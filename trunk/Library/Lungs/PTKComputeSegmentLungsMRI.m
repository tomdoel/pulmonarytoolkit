function [new_image, bounds] = TDComputeSegmentLungsMRI(original_image, filter_size_mm, reporting, start_point_right)
    % TDComputeSegmentLungsMRI. Generates an approximate segmentation the lungs
    % from MRI images using region growing with a variable threshold.
    %
    %
    %     Syntax:
    %         [new_image, bounds] = TDComputeSegmentLungsMRI(original_image, filter_size_mm, reporting, start_point_right)
    %
    %         Inputs:
    %         ------
    %             original_image - The MRI image from which to segment the lungs
    %             filter_size_mm - The standard deviation of the filter to apply
    %             reporting - a TDReporting object for progress, warning and
    %                 error reporting.
    %             start_point_right - optionally specify a starting point
    %
    %         Outputs:
    %         -------
    %             new_image - A binary TDImage containing the segmented lungs
    %             bounds - The image threshold determined for lung segmentation
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if ~isa(original_image, 'TDImage')
        reporting.Error('TDComputeSegmentLungsMRI:BadInput', 'TDComputeSegmentLungsMRI requires a TDImage as input');
    end
    
    % ToDo: This is too specific
    if isa(reporting, 'TDReportingWithCache')
        reporting.PushProgress;
    end    
    
    reporting.UpdateProgressMessage('Finding approximate MRI lung segmentation by region growing');

    original_image = TDGaussianFilter(original_image, filter_size_mm);

    if (nargin < 4)
        reporting.UpdateProgressMessage('Automatically selecting a point in the lung parenchyma');
        start_point_right = AutoFindLungPoint(original_image, false);
        start_point_left = AutoFindLungPoint(original_image, true);
    end
    
    reporting.UpdateProgressMessage('Finding optimal threshold values');
    new_image_left = original_image.Copy;
    new_image_right = original_image.Copy;
    [image_raw_left, bounds_left] = FindMaximumRegionNotTouchingSides(new_image_left, start_point_left, original_image.ImageSize, reporting);
    [image_raw_right, bounds_right] = FindMaximumRegionNotTouchingSides(new_image_right, start_point_right, original_image.ImageSize, reporting);
    
    new_image_left.ChangeRawImage(image_raw_left);
    new_image_right.ChangeRawImage(image_raw_right);
    
    voxel_size = original_image.VoxelSize;
    
    new_image = new_image_left.Copy;
    new_image.ChangeRawImage(uint8((new_image_left.RawImage + new_image_right.RawImage) > 0));

    
    if voxel_size(1) > 5
        new_image.AddBorder(1);
        new_image = TDGetMainRegionExcludingBorder(new_image, reporting);
        new_image.RemoveBorder(1);
        
    else
        new_image = TDGetMainRegionExcludingBorder(new_image, reporting);
    end

    bounds = [0, 0];
    bounds(1) = min(bounds_left(1), bounds_right(1));
    bounds(2) = max(bounds_left(2), bounds_right(2));
    
    % ToDo: This is too specific
    if isa(reporting, 'TDReportingWithCache')
        reporting.PopProgress;
    end
end

function lung_point = AutoFindLungPoint(original_image, find_left)
    image_size = original_image.ImageSize;
    centre_point = round(image_size/2);
    if (find_left)
        adjust_centrepoint = -1;
    else
        adjust_centrepoint = 1;
    end
    centre_point(2) = centre_point(2) + adjust_centrepoint*round(image_size(2)/4);
    search_size = round(image_size/10);
    start_point = centre_point - search_size;
    end_point = centre_point + search_size;
    search_image = original_image.RawImage(...
        start_point(1) : end_point(1), start_point(2) : end_point(2), start_point(3):end_point(3));
    [~, ind] = sort(search_image(:));
    [ic, jc, kc] = ind2sub(size(search_image), ind(1));
    lung_point = [ic jc kc];
    lung_point = lung_point + start_point - [1 1 1];
end

function [new_image, bounds] = FindMaximumRegionNotTouchingSides(lung_image, start_point, voxel_size, reporting)
    new_image = zeros(lung_image.ImageSize, 'int16');
    next_image = new_image;
    min_value = 0;
    max_value = lung_image.RawImage(start_point(1), start_point(2), start_point(3));

    increments = [50 10 1];
    
    start_points_global = [];
    start_points_global{1} = lung_image.LocalToGlobalCoordinates(start_point);
    
    next_image_open = lung_image.BlankCopy;
    
    for increment = increments
        while (~IsTouchingSides(next_image, voxel_size))
            max_value = max_value + increment;
            new_image = next_image;
            next_image = int16((lung_image.RawImage >= min_value) & (lung_image.RawImage <= max_value));
            next_image_open.ChangeRawImage(next_image);
            next_image = TDSimpleRegionGrowing(next_image_open, start_points_global, reporting);
            next_image = next_image.RawImage;
        end
        max_value = max_value - increment;
        next_image = new_image;
    end
    
    bounds = [min_value max_value];
    new_image = logical(new_image);
end

function is_touching_sides = IsTouchingSides(image_to_check, voxel_size)
    if voxel_size(1) < 5
        is_touching_sides = CheckSide(image_to_check(1, :, :)) || ...
            CheckSide(image_to_check(:, 1, :)) || ...
            CheckSide(image_to_check(end, :, :)) || ...
            CheckSide(image_to_check(:, end, :));
    else
        is_touching_sides = CheckSide(image_to_check(:, 1, :)) || ...
            CheckSide(image_to_check(:, end, :));
    end
end

function any_nonzero = CheckSide(side)
    any_nonzero = any(side(:));
end