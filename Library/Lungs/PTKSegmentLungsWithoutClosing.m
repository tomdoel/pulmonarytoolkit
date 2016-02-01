function lung_image = PTKSegmentLungsWithoutClosing(original_image, filter_image, use_wide_threshold, reporting)
    % PTKSegmentLungsWithoutClosing. Extracts a region comprising the lung and
    % airways from a CT region of interest image.
    %
    %
    %     Syntax:
    %         lung_image = PTKSegmentLungsWithoutClosing(original_image, filter_image, use_wide_threshold, reporting)
    %
    %         Inputs:
    %         ------
    %             original_image - The image to filter, in a PTKImage class. This
    %                 should generally be the lung region of interest
    %             filter_image - set to true if a Gaussian filter should be
    %                 applied prior to segmentation. This is better at
    %                 segmenting noisy images (e.g. low dose)
    %                 but may include airway walls
    %             use_wide_threshold - Segment using a larger threshold range.
    %                 This is better at segmenting the lungs for noisy/diseased
    %                 images where voxels take on a wider range of values, but
    %                 may segment airway walls.
    %             reporting - a PTKReporting object for progress, warning and
    %                 error reporting.
    %
    %         Outputs:
    %         -------
    %             lung_image - A binary PTKImage containing the segmented region
    %             which comprises the lungs and airways 
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    if ~isa(original_image, 'PTKImage')
        error('Requires a PTKImage as input');
    end

    if ~exist('use_wide_threshold', 'var')
        use_wide_threshold = false;
    end
    
    if ~isempty(reporting)
        reporting.ShowProgress('Extracting lung');
    end

    % Filter image to reduce noise
    if filter_image
        filter_size = 0.5;
        filtered_lung_image = PTKGaussianFilter(original_image, filter_size);
    else
        filtered_lung_image = original_image.Copy;
    end

    raw_image = original_image.RawImage;
    raw_image(3:end-2, 3:end-2, 3:end-2) = filtered_lung_image.RawImage(3:end-2, 3:end-2, 3:end-2);
    filtered_lung_image.ChangeRawImage(raw_image);
    filtered_lung_image = PTKThresholdAirway(filtered_lung_image, use_wide_threshold);
    filtered_lung_image.BinaryMorph(@imclose, 3);
    
    if ~isempty(reporting)
        reporting.ShowProgress('Searching for largest connected region');
    end

    
    min_volume_warning_limit = 2000;

    % In the event that the central component was not found, we will
    % perform additional opening
    open_params = [2, 4, 6];
    open_index = 1;
    
    % Find the main component, excluding any components touching the border
    lung_image = PTKGetMainRegionExcludingBorder(filtered_lung_image, 1000000, reporting);
    lung_volume = lung_image.Volume;
    still_searching = lung_volume < min_volume_warning_limit;
    
    while still_searching
        open_value = open_params(open_index);
        filtered_lung_image_copy = filtered_lung_image.Copy;
        filtered_lung_image_copy.BinaryMorph(@imerode, open_value);
        adjusted_lung_image = PTKGetMainRegionExcludingBorder(filtered_lung_image_copy, 1000000, reporting);
        
        lung_volume = adjusted_lung_image.Volume;
        
        if lung_volume < min_volume_warning_limit
            open_index = open_index + 1;
            if open_index > length(open_params)
                still_searching = false;
            end
        else
            lung_image = adjusted_lung_image;
            still_searching = false;
        end
    end
    
    if lung_volume < min_volume_warning_limit
        reporting.ShowWarning('PTKSegmentLungsWithoutClosing:LungVolumeSmall', ['The calculated lung volume ' num2str(lung_volume) 'mm^3 is small. This may indicate pathology or a segmentation error. Please manually verify the lung segmentation.'], [])
    end
    
end