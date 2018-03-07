function [new_image, bounds] = PTKSegmentLungsMRISagittal2D(original_image, filter_size_mm, reporting)
    % PTKSegmentLungsMRISagittal2D. Generates an approximate segmentation the lungs
    % from MRI images using region growing with a variable threshold.
    %
    %
    %     Syntax:
    %         [new_image, bounds] = PTKComputeSegmentLungsMRI(original_image, filter_size_mm, reporting, start_point_right)
    %
    %         Inputs:
    %         ------
    %             original_image - The MRI image from which to segment the lungs
    %             filter_size_mm - The standard deviation of the filter to apply
    %             reporting      - an object implementing CoreReportingInterface
    %                              for reporting progress and warnings
    %             start_point_right - optionally specify a starting point
    %
    %         Outputs:
    %         -------
    %             new_image - A binary PTKImage containing the segmented lungs
    %             bounds - The image threshold determined for lung segmentation
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if ~isa(original_image, 'PTKImage')
        reporting.Error('PTKComputeSegmentLungsMRI:BadInput', 'PTKComputeSegmentLungsMRI requires a PTKImage as input');
    end
    
    reporting.PushProgress;
    
    reporting.UpdateProgressMessage('Finding approximate MRI lung segmentation by region growing');

    min_image = original_image.Limits(1);
    filtered_image = original_image.BlankCopy;
    filtered_image.ChangeRawImage(original_image.RawImage - min_image);
    filtered_image = MimGaussianFilter(filtered_image, filter_size_mm);
    
    if (nargin < 4)
        reporting.UpdateProgressMessage('Automatically selecting a point in the lung parenchyma');
        start_point = AutoFindLungPoint(filtered_image);
    end
    
    reporting.UpdateProgressMessage('Finding optimal threshold values');
    
    [image_raw_new, bounds_new] = FindMaximumRegionNotTouchingSides(filtered_image.Copy(), start_point, true, reporting);
    
    
    new_image = original_image.Copy;
    new_image.ChangeRawImage(uint8((image_raw_new) > 0));

    bounds = bounds_new;
    reporting.PopProgress;
end

function lung_point = AutoFindLungPoint(original_image)
    image_size = original_image.ImageSize;
    centre_point = round(image_size/2);
    centre_point(2) = centre_point(2);
    search_size = round(image_size/10);
    start_point = min(max(1, centre_point - search_size), image_size);
    end_point = min(max(1, centre_point + search_size), image_size);
    search_image = original_image.RawImage(...
        start_point(1) : end_point(1), start_point(2) : end_point(2), start_point(3):end_point(3));
    [~, ind] = sort(search_image(:));
    [ic, jc, kc] = ind2sub(size(search_image), ind(1));
    lung_point = [ic jc kc];
    lung_point = lung_point + start_point - [1 1 1];
end

function [new_image, bounds] = FindMaximumRegionNotTouchingSides(lung_image, local_start_point, sagittal_mode, reporting)
    
    % This code deals with the case where there are missing thick coronal slices
    if sagittal_mode
        min_lung_image = lung_image.Limits(1);
        lung_image.AddBorder(1);
        local_start_point = local_start_point + 1;
        lung_image_raw = lung_image.RawImage;
        max_lung_image = lung_image.Limits(2);
        lung_image_raw(1, :, :) = min_lung_image;
        lung_image_raw(end, :, :) = min_lung_image;
        lung_image_raw(:, :, 1) = min_lung_image;
        lung_image_raw(:, :, end) = min_lung_image;
        lung_image_raw(:, 1, :) = max_lung_image;
        lung_image_raw(:, end, :) = max_lung_image;
        lung_image.ChangeRawImage(lung_image_raw);
    end
    
    min_value = lung_image.Limits(1);
    max_value = floor(lung_image.RawImage(local_start_point(1), local_start_point(2), local_start_point(3)));
    
    [new_image, bounds] = GetVariableThreshold(lung_image, min_value, max_value, {local_start_point}, reporting);

    if sagittal_mode
        lung_image.RemoveBorder(1);
        new_image = new_image(2:end-1, 2:end-1, 2:end-1);
    end
end

function [new_image, bounds] = GetVariableThreshold(lung_image, min_value, max_value, start_points, reporting)
    new_image = zeros(lung_image.ImageSize, 'int16');
    next_image = new_image;
    
    increments = [50 10 1];
    
    start_points_global = lung_image.LocalToGlobalCoordinates(cell2mat(start_points'));
    start_points_global = num2cell(start_points_global, 2)';
    
    next_image_open = lung_image.BlankCopy;
    
    for increment = increments
        while (~IsTouchingSides(next_image))
            max_value = max_value + increment;
            new_image = next_image;
            next_image = int16((lung_image.RawImage >= min_value) & (lung_image.RawImage <= max_value));
            
            next_image_open.ChangeRawImage(next_image);
            reporting.PushProgress;
            next_image = PTKSimpleRegionGrowing(next_image_open, start_points_global, reporting);
            reporting.PopProgress;
            next_image = next_image.RawImage;
        end
        max_value = max_value - increment;
        next_image = new_image;
    end
    
    bounds = [min_value max_value];
    new_image = logical(new_image);
end

function is_touching_sides = IsTouchingSides(image_to_check)
    is_touching_sides = CheckSide(image_to_check(1, :, :)) || ...
        CheckSide(image_to_check(end, :, :));
end

function any_nonzero = CheckSide(side)
    any_nonzero = any(side(:));
end