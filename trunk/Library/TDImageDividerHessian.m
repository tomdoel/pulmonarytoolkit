function filtered_image = TDImageDividerHessian(image_data, filter_function, mask, gaussian_sigma, hessian_filter_gaussian, dont_divide, dont_calculate_evals, is_left_lung, reporting)
    % TDImageDividerHessian. Computes a Hessian-based filter for an image, one octant at a time.
    %
    %     This function performs Hessian-based filtering on an image, but 
    %     reduces memory usage by first dividing the image into octants, 
    %     computing the filter for each octant, and then recombining to produce 
    %     an output image.
    %
    %     The function first divides the image into octants by dividing each
    %     dimension in half but allowing for an overlap border. The Hessian
    %     eigevalues are then computed for each octant. The provided function
    %     handle is called for each octant, with the Hessian eigenvalues
    %     provided as inputs. The resulting images are recombined, discarding
    %     the overlap regions
    %
    %     Syntax:
    %         filtered_image = TDImageDividerHessian(image_data, filter_function, gaussian_sigma, hessian_filter_gaussian, dont_divide, dont_calculate_evals, is_left_lung, reporting)
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
    %             dont_calculate_evals - if true, then the eigenvalues are not
    %                 computed. Instead, the Hessian components are input 
    %                 directly into the filter function.
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
    %             function output_wrapper = FilterFunction(hessian_eigenvalues_wrapper)
    %             
    %         This function will be called once for each octant of the image.
    %      
    %         hessian_eigenvalues_wrapper is a TDWrapper object, whose RawImage
    %         property contains an lxmxnx3 matrix containing the 3 eigenvalues
    %         of the Hessian matrix at each point of the image of dimensions
    %         lxmxn. The eigenvalues are ordered by absolute valye with smallest
    %         first.
    % 
    %         In the case that dont_calculate_evals was set to true, the
    %         TDWrapper object instead contains the Hessian components in the
    %         form of a matrix 6xn, where n is the number of eleents in the
    %         matrix. This is the same form as returned by
    %         TDGetHessianComponents.
    %
    %         output_wrapper is a TDWrapper object whose RawImage is the lxmxn
    %         image resulting from the filter.
    %   
    %     Example
    %     -------
    %         See the plugins TDVesselness and TDFissurenessHessianFactor for
    %         examples.
    %
    %         The following code filters the TDImage image_data using a function
    %         FilterFromHessanEigenvalues, which takes in a matrix of
    %         eigenvalues for an image quadrant and returns an image matrix for
    %         that quadrant.
    %
    %         function ComputeFilter
    %             reporting = TDReportingDefault;
    %             gaussian_size_mm = 1.5;
    %             filtered_image = TDImageDividerHessian(image_data, @FilterFunction, [], gaussian_size_mm, [], [], [], [], reporting)
    %         end
    %
    %         function output_wrapper = FilterFunction(hessian_eigenvalues_wrapper)
    %             output_wrapper = TDWrapper;
    %             output_wrapper.RawImage = FilterFromHessanEigenvalues(hessian_eigenvalues_wrapper.RawImage);
    %         end
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    if ~isempty(hessian_filter_gaussian) && ~isempty(mask)
        reporing.Warning('TDImageDividerHessian:MaskAndFilteringNotSupported', 'Currently the function does not support a mask when using Hessian component filtering', []);
    end

    if dont_calculate_evals && ~isempty(mask)
        reporing.Warning('TDImageDividerHessian:MaskAndFilteringNotSupported', 'Currently this function does not support a mask when not computing eigenvalues', []);
    end

    % Check the input image is of the correct form
    if ~isa(image_data, 'TDImage')
        reporing.Error('TDImageDividerHessian:InputImageBadFormat', 'Requires a TDImage as input');
    end
    
    if isempty(dont_divide)
        dont_divide = false;
    end
    
    if isempty(dont_calculate_evals)
        dont_calculate_evals = false;
    end
    
    if isempty(is_left_lung)
        reporting.ShowWarning('TDImageDividerHessian:ArgumentNotSpecified', 'Warning: the argument is_left_lung was not specified, so I''m assuming this is true', []);
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
            reporting.ShowWarning('TDImageDividerHessian:ImageTooSmallForDivision', 'TDImageDivider:ImageTooSmall', 'Image is too small to divide into octants. I will operate on the whole image', []);
            dont_divide = true;
        end
    end

    if dont_divide
        
        % Image will not be divided into octants
        reporting.ShowWarning('TDImageDividerHessian:NoDivide', 'Ignoring image division and operating on entire lung', []);
        hessian_components = TDGetHessianComponents(image_data, mask);
        
        if dont_calculate_evals
            % Call filter with Hessian components
            filtered_image_raw = filter_function(hessian_components, image_size, reporting);
        else
            part_hessian_evals = HessianVectorised(hessian_components, image_size, mask);
            
            % Call filter with the resulting eigenvalues
            filtered_image_raw = filter_function(part_hessian_evals);
        end
        
        filtered_image.ChangeRawImage(filtered_image_raw.RawImage);
        
        
    else
        % Image will be divided into octants
        
        [octant_limits_in, octant_limits_out, octant_limits_result] = ComputeOctantLimits(image_size, overlap_size);
         
        for octant_index = 1 : 8
            reporting.UpdateProgressAndMessage(100*(octant_index - 1 + progress_octant_offset)/progress_max, ['Computing Hessian for ' progress_text ' lung, octant ' num2str(octant_index)]);
            
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
            
            % Compute eigenvalues for this octant
            hessian_components = TDGetHessianComponents(part_image, part_mask);
            
            if ~isempty(hessian_filter_gaussian)
                reporting.UpdateProgressText('Filtering Hessian components');
                for component_index = 1 : 6
                    img = image_data.BlankCopy;
                    img.ChangeRawImage(reshape(hessian_components.RawImage(component_index, :), part_image.ImageSize));
                    img = TDGaussianFilter(img, hessian_filter_gaussian);
                    hessian_components.RawImage(component_index, :) = img.RawImage(:);
                    img.Reset();
                end
            end
            
            if dont_calculate_evals
                % Call filter with Hessian components
                part_filtered_image = filter_function(hessian_components, part_image.ImageSize, reporting);
            else
                part_hessian_evals = HessianVectorised(hessian_components, part_image.ImageSize, part_mask);
                
                % Call filter with the resulting eigenvalues
                part_filtered_image = filter_function(part_hessian_evals);
            end
            
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
                part_image_raw = part_image.RawImage;
                part_image_raw(:) = 0;
                part_image_raw(part_mask.RawImage(:)) = part_filtered_image.RawImage;

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

% Compute eigenvalues of the Hessian matrix and store in a TDWrapper object
function hessian_eigvals = HessianVectorised(hessian_components, reduced_image_size, mask)
    [~, evals_v] = TDFastEigenvalues(hessian_components.RawImage, true);
    
    hessian_eigvals = TDWrapper;
    if isempty(mask)
        hessian_eigvals.RawImage = zeros([reduced_image_size, 3], 'single');
        hessian_eigvals.RawImage(:,:,:,1) = reshape(evals_v(1, :), reduced_image_size);
        hessian_eigvals.RawImage(:,:,:,2) = reshape(evals_v(2, :), reduced_image_size);
        hessian_eigvals.RawImage(:,:,:,3) = reshape(evals_v(3, :), reduced_image_size);
    else
        linear_image_size = sum(mask.RawImage(:));
        hessian_eigvals.RawImage = zeros([linear_image_size, 3], 'single');
        hessian_eigvals.RawImage(:,1) = reshape(evals_v(1, :), [linear_image_size, 1]);
        hessian_eigvals.RawImage(:,2) = reshape(evals_v(2, :), [linear_image_size, 1]);
        hessian_eigvals.RawImage(:,3) = reshape(evals_v(3, :), [linear_image_size, 1]);
    end
end

