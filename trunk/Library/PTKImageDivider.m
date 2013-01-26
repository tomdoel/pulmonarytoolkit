function filtered_image = TDImageDivider(image_data, filter_function, mask, gaussian_sigma, hessian_filter_gaussian, dont_divide, is_left_lung, reporting)
    % TDImageDivider. Computes a filter for an image, one octant at a time.
    
    %
    %     This function performs filtering on an image, but 
    %     reduces memory usage by first dividing the image into octants, 
    %     computing the filter for each octant, and then recombining to produce 
    %     an output image.
    %
    %     The function first divides the image into octants by dividing each
    %     dimension in half but allowing for an overlap border. The provided function
    %     handle is called for each octant, with the subimage
    %     provided as input. The resulting images are recombined, discarding
    %     the overlap regions
    %
    %     Syntax:
    %         filtered_image = TDImageDivider(image_data, filter_function, gaussian_sigma, hessian_filter_gaussian, dont_divide, is_left_lung, reporting)
    %
    %             image_data - The image to filter, in a TDImage class
    %             filter_function - handle to a user-defined filter function 
    %                 which is to be applied to each quadrant. See below for syntax.
    %             mask - a logical matrix specifying which elements of
    %                 image_data should be processed.
    %             gaussian_sigma - The size of the Gaussian filter to be applied to the whole image
    %                 before filtering using the supplied function. Specify [] for no filtering.
    %             hessian_filter_gaussian - Gaussian filter size to be applied
    %                 to each component of the Hessian matrix before filtering 
    %                 using the supplied function. Specify [] for no filtering.
    %             dont_divide - If true, then the image is not divided into
    %                 quadrants. A value of [] is equivalent to false.
    %             is_left_lung - used for progress reporting. Specify true if
    %                 the functin is currently computing values for the left 
    %                 lung. The progress reporting assumes the right lung is
    %                 computed first, and corresponds to the first half of the
    %                 progress bar. Processing the left lung corresponds to the
    %                 right half of the progress bar. If [] is specified, the
    %                 left lung is assumed and a warning is issued.
    %             reporting - a TDReporting object for progress, warning and
    %                 error reporting.
    %     Notes
    %     -----
    %         The filter_function is a handle to a function of the form
    %             function output_wrapper = FilterFunction(subimage, mask)
    %             
    %         This function will be called once for each octant of the image.
    %      
    %         subimage is a TDImage object, containing the image octant.
    %
    %         output_wrapper is a TDImage object containing the image resulting 
    %             from the filter.
    %   
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    if ~isempty(hessian_filter_gaussian) && ~isempty(mask)
        reporing.Warning('TDImageDivider:MaskAndFilteringNotSupported', 'Currently the function does not support a mask when using Hessian component filtering', []);
    end

    % Check the input image is of the correct form
    if ~isa(image_data, 'TDImage')
        reporing.Error('TDImageDivider:InputImageBadFormat', 'Requires a TDImage as input');
    end
    
    if isempty(dont_divide)
        dont_divide = false;
    end
    
    if isempty(is_left_lung)
        reporting.ShowWarning('TDImageDivider:ArgumentNotSpecified', 'The argument is_left_lung was not specified, so I''m assuming this is true', []);
        is_left_lung = true;
    end
  
    % Gaussian filter
    if ~isempty(gaussian_sigma) && (gaussian_sigma > 0)
        image_data = TDGaussianFilter(image_data, gaussian_sigma);
    end
    
    % Progress ia split between left and right lungs
    if (is_left_lung)
        progress_text = 'left';
        progress_octant_offset = 0;
    else
        progress_text = 'right';
        progress_octant_offset = 0;
    end
    progress_max = 9;
    
    output_size = [image_data.ImageSize];
    filtered_image_raw = zeros(output_size, 'single');
    filtered_image = image_data.BlankCopy;
    
    overlap_size = 10;
    image_size = image_data.ImageSize;

    % If the image is small in any dimension, we will operate on the entire
    % image instead of dividing
    if any(image_size < (2*overlap_size + 2))
        if ~dont_divide
            reporting.ShowWarning('TDImageDivider:ImageTooSmallForDivision', 'TDImageDivider:ImageTooSmall', 'Image is too small to divide into octants. I will operate on the whole image', []);
            dont_divide = true;
        end
    end

    if dont_divide
        
        % Image will not be divided into octants
        reporting.ShowWarning('TDImageDivider:NoDivide', 'Ignoring image division and operating on entire lung', []);
        
        % Call filter with full image
        filtered_image_raw = filter_function(image_data, mask);
        
        filtered_image.ChangeRawImage(filtered_image_raw.RawImage);
        
        
    else
        % Image will be divided into octants
        
        [octant_limits_in, octant_limits_out, octant_limits_result] = ComputeOctantLimits(image_size, overlap_size);
         
        for octant_index = 1 : 8
            reporting.UpdateProgressAndMessage(100*(octant_index - 1 + progress_octant_offset)/progress_max, ['Computing for ' progress_text ' lung, octant ' num2str(octant_index)]);
            
            limits_in = octant_limits_in(octant_index, :);
            limits_out = octant_limits_out(octant_index, :);
            limits_result = octant_limits_result(octant_index, :);
            
            % Fetch image for this octant
            part_image = image_data.Copy;
            part_image.Crop([limits_in(1), limits_in(3), limits_in(5)], [limits_in(2), limits_in(4), limits_in(6)]);
            
            if isempty(mask)
                part_mask = [];
            else
                % Fetch mask for this octant
                part_mask = mask.Copy;
                part_mask.Crop([limits_in(1), limits_in(3), limits_in(5)], [limits_in(2), limits_in(4), limits_in(6)]);
            end
            
            part_filtered_image = filter_function(part_image, part_mask);

            if isempty(mask)
                
                % Place results in output matrix, ignoring border regions
                filtered_image_raw( ...
                    limits_result(1):limits_result(2), ...
                    limits_result(3):limits_result(4), ...
                    limits_result(5):limits_result(6) ...
                    ) = part_filtered_image.RawImage( ...
                    limits_out(1):limits_out(2), ...
                    limits_out(3):limits_out(4), ...
                    limits_out(5):limits_out(6) ...
                    );
            else
                part_image_raw = zeros(part_image.ImageSize, 'single');
                part_image_raw(part_mask.RawImage) = part_filtered_image.RawImage(part_mask.RawImage);
                
                % Place results in output matrix, ignoring border regions
                filtered_image_raw( ...
                    limits_result(1):limits_result(2), ...
                    limits_result(3):limits_result(4), ...
                    limits_result(5):limits_result(6) ...
                    ) = part_image_raw( ...
                    limits_out(1):limits_out(2), ...
                    limits_out(3):limits_out(4), ...
                    limits_out(5):limits_out(6) ...
                    );
            end
        end
        reporting.UpdateProgressAndMessage(100*((8+progress_octant_offset)/progress_max), ['Storing results for ' progress_text ' lung']);
        filtered_image.ChangeRawImage(filtered_image_raw);
    end 
end

% Finds coordinates of each image quadrant, allowing an overlap
function [octant_limits_in, octant_limits_out, octant_limits_result] = ComputeOctantLimits(image_size, overlap_size)
    mid_point = round(image_size / 2);

    i_min_in = [1, mid_point(1) - overlap_size];
    i_min_out = [1, 1 + overlap_size];
    i_min_result = [1, mid_point(1)];

    i_max_in = [mid_point(1) + overlap_size, image_size(1)];
    i_max_out = [mid_point(1), 1 + image_size(1) - (mid_point(1) - overlap_size)];
    i_max_result = [mid_point(1), image_size(1)];

    j_min_in = [1, mid_point(2) - overlap_size];
    j_min_out = [1, 1 + overlap_size];
    j_min_result = [1, mid_point(2)];

    j_max_in = [mid_point(2) + overlap_size, image_size(2)];
    j_max_out = [mid_point(2), 1 + image_size(2) - (mid_point(2) - overlap_size)];
    j_max_result = [mid_point(2), image_size(2)];

    k_min_in = [1, mid_point(3) - overlap_size];
    k_min_out = [1, 1 + overlap_size];
    k_min_result = [1, mid_point(3)];

    k_max_in = [mid_point(3) + overlap_size, image_size(3)];
    k_max_out = [mid_point(3), 1 + image_size(3) - (mid_point(3) - overlap_size)];
    k_max_result = [mid_point(3), image_size(3)];

    octant_limits_in = zeros(8, 6);
    octant_limits_out = zeros(8, 6);
    octant_limits_result = zeros(8, 6);

    for octant_index = 1 : 8
        % Calculate image boundaries for each octant
        [q_i, q_j, q_k] = ind2sub([2 2 2], octant_index);
        octant_limits_in(octant_index, :) = [i_min_in(q_i), i_max_in(q_i), j_min_in(q_j), j_max_in(q_j), k_min_in(q_k), k_max_in(q_k)];
        octant_limits_out(octant_index, :) = [i_min_out(q_i), i_max_out(q_i), j_min_out(q_j), j_max_out(q_j), k_min_out(q_k), k_max_out(q_k)];
        octant_limits_result(octant_index, :) = [i_min_result(q_i), i_max_result(q_i), j_min_result(q_j), j_max_result(q_j), k_min_result(q_k), k_max_result(q_k)];
    end

end