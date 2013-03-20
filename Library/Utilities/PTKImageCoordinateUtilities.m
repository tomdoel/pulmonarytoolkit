classdef PTKImageCoordinateUtilities
    % PTKImageCoordinateUtilities. Utility functions related to processing 3D
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
            linear_offsets = PTKImageCoordinateUtilities.GetLinearOffsetsForDirections(dirs, image_size);
            
            dirs = 1:27;
            linear_offsets27 = PTKImageCoordinateUtilities.GetLinearOffsetsForDirections(dirs, image_size);
        end
        
        function linear_offsets = GetLinearOffsetsForDirections(dirs, image_size)
            direction_vectors = PTKImageCoordinateUtilities.CalculateDirectionVectors;            
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

            % Note that i,j,k can be negative, in the case where a border has
            % been added to the image so its coordinates extend beyond the
            % boundaries of the original image
            
            new_indices = 1 + (i) + (j)*size_big(1) + (k)*size_big(1)*size_big(2);
        end
        
        % Creates an image cropped to the smallest box size that encloses all
        % the points specified by their linear indices.
        function [offset reduced_image reduced_image_size] = GetMinimalImageForIndices(indices, image_size)
            if size(indices, 1) > 1
                error('GetMinimalImageForIndices requires indices to be in a row vector');
            end
            indices = int32(indices);
            [i, j, k] = PTKImageCoordinateUtilities.FastInd2sub(image_size, indices);
            
            voxel_coordinates = [i' j' k'];
            mins = min(voxel_coordinates, [], 1);
            maxs = max(voxel_coordinates, [], 1);
            reduced_image_size = maxs - mins + int32([1 1 1]);
            reduced_image = false(reduced_image_size);
            offset = mins - 1;
            i = PTKImageCoordinateUtilities.FastSub2ind(reduced_image_size, voxel_coordinates(:,1)-offset(1), voxel_coordinates(:,2)-offset(2), voxel_coordinates(:,3)-offset(3));
            
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
        
        function affine_matrix = CreateAffineTranslationMatrix(x)
            affine_matrix = zeros(3, 4, 'single');
            affine_matrix(1, 1) = 1;
            affine_matrix(2, 2) = 1;
            affine_matrix(3, 3) = 1;
            affine_matrix(4, 4) = 1;
            affine_matrix(1:3, 4) = x;
        end
        
        function affine_matrix = CreateRigidAffineMatrix(x)
            affine_matrix = zeros(3, 4, 'single');
            
            euler_rot_matrix = PTKImageCoordinateUtilities.GetEulerRotationMatrix(x(1), x(2), x(3));
            affine_matrix(1:3, 1:3) = euler_rot_matrix;
            affine_matrix(1:3, 4) = x(4:6);
            
            affine_matrix = [affine_matrix; [0 0 0 1]];
        end
        
        function [i, j, k] = TransformCoordsAffine(i, j, k, augmented_matrix)
            [j, i, k] = PTKImageCoordinateUtilities.TranslateAndRotateMeshGrid(j, i, k, augmented_matrix(1:3,1:3), augmented_matrix(1:3,4));
        end
        
        function [i, j, k] = TransformCoordsFluid(i, j, k, deformation_field)
            i = i - deformation_field.RawImage(:,:,:,1);
            j = j - deformation_field.RawImage(:,:,:,2);
            k = k - deformation_field.RawImage(:,:,:,3);
        end
        
        function [X, Y, Z] = TranslateAndRotateMeshGrid(X, Y, Z, rot_matrix, trans_matrix)
            % Rotates and translates meshgrid generated coordinates in 3D
            % Note coordinates are [XYZ] NOT [IJK]
            [X, Y, Z] = PTKImageCoordinateUtilities.RotateMeshGrid(X + trans_matrix(1), Y + trans_matrix(2), Z + trans_matrix(3), rot_matrix);
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
        
        function affine_matrix = GetAffineTranslationFromPatientPosition(image_1, image_2)
            translation = (image_1.GlobalOrigin - image_2.GlobalOrigin);
            translation = translation([2 1 3]);
            translation(3) = - translation(3);
            affine_matrix = PTKImageCoordinateUtilities.CreateAffineTranslationMatrix(translation);
        end
    
        % To combine a rigid transformation with a nonrigid deformation field, 
        % compute the change in image coordinates after applying the
        % deformation field and then the rigid affine transformation.
        function deformation_field = AdjustDeformationFieldForInitialAffineTransformation(deformation_field, affine_initial_matrix)
            
            [df_i, df_j, df_k] = deformation_field.GetCentredGlobalCoordinatesMm;
            [df_i, df_j, df_k] = ndgrid(df_i, df_j, df_k);
            [df_i_t, df_j_t, df_k_t] = PTKImageCoordinateUtilities.TransformCoordsFluid(df_i, df_j, df_k, deformation_field);
            [df_i_t, df_j_t, df_k_t] = PTKImageCoordinateUtilities.TransformCoordsAffine(df_i_t, df_j_t, df_k_t, affine_initial_matrix);
            
            deformation_field_raw = zeros(deformation_field.ImageSize);
            deformation_field_raw(:,:,:,1) = df_i - df_i_t;
            deformation_field_raw(:,:,:,2) = df_j - df_j_t;
            deformation_field_raw(:,:,:,3) = df_k - df_k_t;
            deformation_field2 = deformation_field.BlankCopy;
            deformation_field2.ChangeRawImage(deformation_field_raw);
            deformation_field = deformation_field2;
        end
        
        % Returns a vector which defines the order in which the dimensions of an
        % DICOM image volume should be permuted in order to align it with the
        % PTK coordinate system
        function permutation_vector = GetDimensionPermutationVectorFromDicomOrientation(orientation, reporting)
            % The orientation vector is formed of cosines. Typically these will
            % be 1s and 0s but we allow for small variations in the angles.
            orientation = round(abs(orientation));
            
            % DICOM coordinates are XYZ but Matlab's coordinates are YXZ. We
            % convert the orientation to Matlab coordinates, which we refer to as IJK.
            orientation_i = orientation([5, 4, 6])'; % Direction of first image axis in ijk (=yxz) coordinates
            orientation_j = orientation([2, 1, 3])'; % Direction of second image axis in ijk (=yxz) coordinates
            
            % Determine which PTK dimension each of these vectors corresponds to
            dimension_i = PTKImageCoordinateUtilities.GetDimensionIndexFromOrientation(orientation_i, reporting);
            dimension_j = PTKImageCoordinateUtilities.GetDimensionIndexFromOrientation(orientation_j, reporting);
            
            permutation_vector = [3, 3, 3];
            permutation_vector(dimension_i) = 1;
            permutation_vector(dimension_j) = 2;
            
            % Check the resulting vector is valid
            if (sum(permutation_vector == 1) ~= 1) || (sum(permutation_vector == 2) ~= 1) || (sum(permutation_vector == 3) ~= 1) || ...
                    ~isempty(setdiff(permutation_vector, [1,2,3]))
                reporting.Error('PTKImageCoordinateUtilities:InvalidPermutationVector', 'GetDimensionPermutationVectorFromDicomOrientation() resulted in an invalid permutation vector');
            end
        end
        
        function dimension_number = GetDimensionIndexFromOrientation(orientation_vector, reporting)
            if isequal(orientation_vector, [1, 0, 0]) || isequal(orientation_vector, [1; 0; 0])
                dimension_number = 1;
            elseif isequal(orientation_vector, [0, 1, 0]) || isequal(orientation_vector, [0; 1; 0])
                dimension_number = 2;
            elseif isequal(orientation_vector, [0, 0, 1]) || isequal(orientation_vector, [0; 0; 1])
                dimension_number = 3;
            else
                reporting.Error('PTKImageCoordinateUtilities:UnknownOrientationVector', 'GetDimensionIndexFromOrientation() was called with an unknown orientation vector.');
            end
        end
    end
end

