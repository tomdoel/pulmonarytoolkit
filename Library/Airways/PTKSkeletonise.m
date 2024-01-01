function binary_image = PTKSkeletonise(binary_image, fixed_points_global, reporting)
    % Perform a skeletonisation on a segmented airway tree.
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    if ~isa(binary_image, 'PTKImage')
        error('Requires a PTKImage as input');
    end
    
    if ~exist('reporting', 'var')
        reporting = CoreReportingDefault();
    end
    
    if isdeployed || exist('PTKFastIsSimplePoint') == 3 %#ok<EXIST>
        use_mex_simple_point = true;
    else
        use_mex_simple_point = false;
        warning_message = 'Could not find compiled mex file PTKFastIsSimplePoint. Using a slower version PTKIsSimplePoint instead. Increase program speed by running mex PTKFastIsSimplePoint.cpp in the mex folder.';
        reporting.ShowWarning('PTKSkeletonise:PTKFastIsSimplePointnotFound', warning_message, []);
    end
    
    fixed_points = binary_image.GlobalToLocalIndices(fixed_points_global);
    
    % Marks endpoints with 3
    binary_image = binary_image.Copy;
    binary_image.ChangeRawImage(MarkEndpoints(binary_image.RawImage, fixed_points));
    total_number_of_points = sum(binary_image.RawImage(:) > 0);

    binary_image.AddBorder(2);
    direction_vectors = CalculateDirectionVectors;
    
    raw_image = binary_image.RawImage;

    previous_image = zeros(size(raw_image), 'uint8');

    iteration = 0;
    
    while ~isequal(previous_image, raw_image)
        previous_image = raw_image;
        
        iteration = iteration + 1;
        if (iteration > 20)
            if isempty(reporting)
                error('Maximum number of iterations exceeded. This can occur if not all the airway endpoints have been specified correctly.');
            else
                reporting.Error('PTKSkeletonise:MaximumIterationsExceeded', 'Maximum number of iterations exceeded. This can occur if not all the airway endpoints have been specified correctly.');
            end
        end
                

        % For each of the 6 principal directions
        for direction = [5, 23, 11, 17, 13, 15]
            
            if ~isempty(reporting)
                number_remaining_points = sum(raw_image(:) > 0);
                progress_value = round(100*(1-number_remaining_points/total_number_of_points));
                reporting.UpdateProgressAndMessage(progress_value, ['Skeletonisation: Iteration ' int2str(iteration)]);
            end
            
            if ~isempty(reporting)
                if reporting.HasBeenCancelled
                    error('User cancelled');
                end
            end
            
            direction_vector = direction_vectors(direction,:);
            i = direction_vector(1);
            j = direction_vector(2);
            k = direction_vector(3);
            
            % Detect border points and get their indices
            [b_i, b_j, b_k] = ind2sub(size(raw_image) - [2 2 2], ...
                find((1 == raw_image(2:end-1, 2:end-1, 2:end-1)) & (0 == raw_image(2+i:end-1+i,2+j:end-1+j,2+k:end-1+k))));
            b_i = b_i + 1; b_j = b_j + 1; b_k = b_k + 1;
            
            % Iterate through each border point and delete (set to zero) if
            % it is a simple point
            for i = 1 : length(b_i)
                raw_image(b_i(i), b_j(i), b_k(i)) = ~IsPointSimple(raw_image, b_i(i), b_j(i), b_k(i), use_mex_simple_point);
            end
        end
    end
    binary_image.ChangeRawImage(raw_image);
    binary_image.RemoveBorder(2);
end

function is_simple = IsPointSimple(binary_image, i, j, k, use_mex_simple_point)
    if use_mex_simple_point
        % MEX function (fast)
        is_simple = PTKFastIsSimplePoint((binary_image(i-1:i+1, j-1:j+1, k-1:k+1)));
    else
        % Matlab function (slow)
        is_simple = PTKIsSimplePoint(binary_image(i-1:i+1, j-1:j+1, k-1:k+1));
    end
end

function binary_image = MarkEndpoints(binary_image, fixed_points)        
    binary_image = int8(binary_image ~= 0);
    binary_image(fixed_points) = 3;
end


function direction_vectors = CalculateDirectionVectors
    [i, j, k] = ind2sub([3 3 3], 1 : 27);
    direction_vectors = [i' - 2, j' - 2, k' - 2];
end