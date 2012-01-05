classdef TDImageCoordinateUtilities
    % TDImageCoordinateUtilities. Utility functions related to processing 3D
    % image coordinates
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods (Static)
        
        % In Matlab, matrices can be represented as a linear vector. So every
        % point in a 3D matrix has a linear index as well as an i-j-k
        % coordinate. This function returns the 'offset' values which can be
        % added to the linear index of any point to return the linear indices of
        % its nearest neighbours.
        function [linear_offsets, linear_offsets27] = GetLinearOffsets(image_size)
            direction_vectors = TDImageCoordinateUtilities.CalculateDirectionVectors;
            
            % Compute linear index offsets for diretion vectors
            linear_offsets = zeros(1, 6);
            
            dirs = [5, 23, 11, 17, 13, 15];
            for n = 1 : length(dirs)
                direction = dirs(n);
                direction_vector = direction_vectors(direction, :);
                i_start_point = [2 2 2];
                i_end_point = i_start_point + direction_vector;
                i = [i_start_point(1); i_end_point(1)];
                j = [i_start_point(2); i_end_point(2)];
                k = [i_start_point(3); i_end_point(3)];
                linear_indices = sub2ind(image_size, i, j, k);
                linear_offsets(n) = linear_indices(2) - linear_indices(1);
            end
            
            
            linear_offsets27 = zeros(1, 27);
            dirs = 1:27;
            for n = 1 : length(dirs)
                direction = dirs(n);
                direction_vector = direction_vectors(direction, :);
                i_start_point = [2 2 2];
                i_end_point = i_start_point + direction_vector;
                i = [i_start_point(1); i_end_point(1)];
                j = [i_start_point(2); i_end_point(2)];
                k = [i_start_point(3); i_end_point(3)];
                linear_indices = sub2ind(image_size, i, j, k);
                linear_offsets27(n) = linear_indices(2) - linear_indices(1);
            end
        end
        
        % Returns the coordinates of each point in a 3x3x3 matrix relative to
        % its centre
        function direction_vectors = CalculateDirectionVectors
            [i, j, k] = ind2sub([3 3 3], 1:27);
            direction_vectors = [i' - 2, j' - 2, k' - 2];
        end

        % This function alters matrix indices to transform from a smaller matix to
        % a bigger one
        function new_indices = OffsetIndices(indices, offset, size_small, size_big)
            indices_i = (indices - 1);
            div1 = (size_small(1));
            div2 = (size_small(1)*size_small(2));
            
            k_mod = rem(indices_i, div2);
            
            k = (indices_i - k_mod)/div2; % Equivalent to idivide but quicker
            
            i = mod(k_mod, div1);
            
            j = (k_mod - i)/div1; % Equivalent to idivide but quicker
            
            i = i + offset(1);
            j = j + offset(2);
            k = k + offset(3);
            
            new_indices = 1 + (i) + (j)*size_big(1) + (k)*size_big(1)*size_big(2);
        end
        
        % Creates an image cropped to the smallest box size that encloses all
        % the points specified by their linear indices.
        function [offset reduced_image reduced_image_size] = GetMinimalImageForIndices(indices, image_size)
            if size(indices, 1) > 1
                error('GetMinimalImageForIndices requires indices to be in a row vector');
            end
            indices = int32(indices);
            [i, j, k] = TDImageCoordinateUtilities.FastInd2sub(image_size, indices);
            
            voxel_coordinates = [i' j' k'];
            mins = min(voxel_coordinates, [], 1);
            maxs = max(voxel_coordinates, [], 1);
            reduced_image_size = maxs - mins + int32([1 1 1]);
            reduced_image = false(reduced_image_size);
            offset = mins - 1;
            i = TDImageCoordinateUtilities.FastSub2ind(reduced_image_size, voxel_coordinates(:,1)-offset(1), voxel_coordinates(:,2)-offset(2), voxel_coordinates(:,3)-offset(3));
            
            reduced_image(i) = true;
        end
        
        % A faster alternative to Ind2sub
        function [i, j, k] = FastInd2sub(im_size, indices)
            indices = indices - 1;
            div1 = (im_size(1));
            div2 = ((im_size(1)*im_size(2)));
            
            k_mod = rem(indices, div2);
            
            k = 1 + (indices - k_mod)/div2; % Equivalent to idivide but quicker
            i = 1 + mod(k_mod, im_size(1));
            j = 1 + (k_mod - i + 1)/div1; % Equivalent to idivide but quicker
        end
        
        function indices = FastSub2ind(im_size, i, j, k)
            indices = i + (j-1)*im_size(1) + (k-1)*im_size(1)*im_size(2);
        end
        
    end
end

