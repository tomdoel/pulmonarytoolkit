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
            % Compute linear index offsets for diretion vectors
            dirs = [5, 23, 11, 17, 13, 15];
            linear_offsets = TDImageCoordinateUtilities.GetLinearOffsetsForDirections(dirs, image_size);
            
            dirs = 1:27;
            linear_offsets27 = TDImageCoordinateUtilities.GetLinearOffsetsForDirections(dirs, image_size);
        end
        
        function linear_offsets = GetLinearOffsetsForDirections(dirs, image_size)
            direction_vectors = TDImageCoordinateUtilities.CalculateDirectionVectors;            
            linear_offsets = zeros(1, numel(dirs));
            for n = 1 : length(dirs)
                direction = dirs(n);
                direction_vector = direction_vectors(direction, :);
                start_point = [2 2 2];
                i_end_point = start_point + direction_vector;
                i = [start_point(1); i_end_point(1)];
                j = [start_point(2); i_end_point(2)];
                k = [start_point(3); i_end_point(3)];
                linear_indices = sub2ind(image_size, i, j, k);
                linear_offsets(n) = linear_indices(2) - linear_indices(1);
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
            if any(i < 0) || any(j < 0) || any(k < 0)
                error('OffsetIndices: The indices are out of range for this image');
            end
            
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

        function rot_matrix = GetEulerRotationMatrix(phi, theta, psi)
            rot_matrix = zeros(3,3);
            
            rot_matrix(1, 1) = cos(psi)*cos(phi) - cos(theta)*sin(phi)*sin(psi);
            rot_matrix(1, 2) = cos(psi)*sin(phi) + cos(theta)*cos(phi)*sin(psi);
            rot_matrix(1, 3) = sin(psi)*sin(theta);
            
            rot_matrix(2, 1) = -sin(psi)*cos(phi) - cos(theta)*sin(phi)*cos(psi);
            rot_matrix(2, 2) = -sin(psi)*sin(phi) + cos(theta)*cos(phi)*cos(psi);
            rot_matrix(2, 3) = cos(psi)*sin(theta);
            
            rot_matrix(3, 1) =  sin(theta)*sin(phi);
            rot_matrix(3, 2) = -sin(theta)*cos(psi);
            rot_matrix(3, 3) = cos(theta);
        end
        
        function affine_matrix = CreateAffineMatrix(x)
            affine_matrix = zeros(3, 4, 'single');
            affine_matrix(:) = x(:);
            affine_matrix = [affine_matrix; [0 0 0 1]];
        end
        
        function affine_matrix = CreateRigidAffineMatrix(x)
            affine_matrix = zeros(3, 4, 'single');
            
            euler_rot_matrix = TDImageCoordinateUtilities.GetEulerRotationMatrix(x(1), x(2), x(3));
            affine_matrix(1:3, 1:3) = euler_rot_matrix;
            
            affine_matrix(1:3,4) = x(4:6);
            
            affine_matrix = [affine_matrix; [0 0 0 1]];
        end
        
        function [i, j, k] = TransformCoordsAffine(i, j, k, augmented_matrix)
            [j, i, k] = TDImageCoordinateUtilities.TranslateAndRotateMeshGrid(j, i, k, augmented_matrix(1:3,1:3), augmented_matrix(1:3,4));
        end
        
        function [X, Y, Z] = TranslateAndRotateMeshGrid(X, Y, Z, rot_matrix, trans_matrix)
            % Rotates and translates meshgrid generated coordinates in 3D
            [X, Y, Z] = TDImageCoordinateUtilities.RotateMeshGrid(X + trans_matrix(1), Y + trans_matrix(2), Z + trans_matrix(3), rot_matrix);
        end

        function [X, Y, Z] = RotateMeshGrid(X, Y, Z, rot_matrix)
            % Rotates coordinates that are given in 3D meshgrid matrices
            coords = rot_matrix * [ ...
                reshape(X, 1, numel(X)); ...
                reshape(Y, 1, numel(Y)); ...
                reshape(Z, 1, numel(Z)) ...
                ];
            
            X = reshape(coords(1, :), size(X));
            Y = reshape(coords(2, :), size(Y));
            Z = reshape(coords(3, :), size(Z));
        end
    end
end

