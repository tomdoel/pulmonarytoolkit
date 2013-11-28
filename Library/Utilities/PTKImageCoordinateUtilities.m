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
            
            % Get the coordinates of the centre of the first voxel in image1,
            % relative to the centre of image1
            [i1, j1, k1] = image_1.GlobalCoordinatesToCoordinatesMm([1, 1, image_1.OriginalImageSize(3)]);
            [i1, j1, k1] = image_1.GlobalCoordinatesMmToCentredGlobalCoordinatesMm(i1, j1, k1);
            image_1_origin_coordinates = [i1, j1, k1];
            image_1_centre_coordinates = image_1.GlobalOrigin - image_1_origin_coordinates;
            
            % Get the coordinates of the centre of the first voxel in image2,
            % relative to centre of image2
            [i2, j2, k2] = image_2.GlobalCoordinatesToCoordinatesMm([1, 1, image_2.OriginalImageSize(3)]);
            [i2, j2, k2] = image_2.GlobalCoordinatesMmToCentredGlobalCoordinatesMm(i2, j2, k2);
            image_2_origin_coordinates = [i2, j2, k2];
            image_2_centre_coordinates = image_2.GlobalOrigin - image_2_origin_coordinates;
            
            translation = image_1_centre_coordinates - image_2_centre_coordinates;

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
        function [permutation_vector, flip] = GetDimensionPermutationVectorFromDicomOrientation(orientation, reporting)
            % DICOM coordinates are XYZ but Matlab's coordinates are YXZ. We
            % convert the orientation to Matlab coordinates, which we refer to as IJK.
            orientation_1 = orientation([5, 4, 6])'; % Direction of first image axis in ijk (=yxz) coordinates
            orientation_2 = orientation([2, 1, 3])'; % Direction of second image axis in ijk (=yxz) coordinates
            
            % By swtching the i and j axes we have inverted the coordinate
            % system, so we need to flip the k dimension
            orientation_1(3) = - orientation_1(3);
            orientation_2(3) = - orientation_2(3);
            
            % Determine the PTK dimensions to which each of these vectors correspond
            dimension_1 = PTKImageCoordinateUtilities.GetDimensionIndexFromOrientation(orientation_1, reporting);
            dimension_2 = PTKImageCoordinateUtilities.GetDimensionIndexFromOrientation(orientation_2, reporting);

            permutation_vector = [3, 3, 3];
            permutation_vector(dimension_1) = 1;
            permutation_vector(dimension_2) = 2;
            
            flip = PTKImageCoordinateUtilities.GetFlip(orientation, reporting);

            % Check the resulting vector is valid
            if (sum(permutation_vector == 1) ~= 1) || (sum(permutation_vector == 2) ~= 1) || (sum(permutation_vector == 3) ~= 1) || ...
                    ~isempty(setdiff(permutation_vector, [1,2,3]))
                reporting.Error('PTKImageCoordinateUtilities:InvalidPermutationVector', 'GetDimensionPermutationVectorFromDicomOrientation() resulted in an invalid permutation vector');
            end
        end
        
        function dimension_number = GetDimensionIndexFromOrientation(orientation_vector, reporting)
            % The orientation vector is formed of cosines. Typically these will
            % be 1s and 0s but we allow for small variations in the angles.
            orientation_vector = round(abs(orientation_vector));
            
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
        
        function flip = GetFlip(orientation, reporting)
            % The orientation vector is formed of cosines. Typically these will
            % be 1s and 0s but we allow for small variations in the angles.
            orientation_vector = round(abs(orientation));
            
            if isequal(orientation_vector, [1, 0, 0, 0, 1, 0]) || isequal(orientation_vector, [1; 0; 0; 0; 1; 0])
                flip = [false, false, true];
            elseif isequal(orientation_vector, [0, 1, 0, 1, 0, 0]) || isequal(orientation_vector, [1; 0; 0; 0; 1; 0])
                flip = [false, false, true];
            elseif isequal(orientation_vector, [1, 0, 0, 0, 0, 1]) || isequal(orientation_vector, [1; 0; 0; 0; 0; 1])
                flip = [false, false, false];
            elseif isequal(orientation_vector, [0, 1, 0, 0, 0, 1]) || isequal(orientation_vector, [0; 1; 0; 0; 0; 1])
                flip = [false, false, false];
            else
                reporting.Error('PTKImageCoordinateUtilities:UnknownOrientationVector', 'GetDimensionIndexFromOrientation() was called with an unknown orientation vector.');
            end
        end
        
        function spline_points = CreateSplineCurve(points, num_points)
            number_of_points = size(points, 1);
            number_of_coordinates = size(points, 2);
            extended_points = zeros(number_of_points + 2, number_of_coordinates);
            extended_points(2 : number_of_points + 1, :) = points;
            extended_points(1, :) = extended_points(2, :) - (extended_points(3, :) - extended_points(2, :));
            extended_points(end, :) = extended_points(end - 1, :) - (extended_points(end - 2, : ) - extended_points(end - 1, :));
            
            extended_number_of_points = size(extended_points, 1);
            interval_values = linspace(0, 1, num_points + 1);
            interval_values2 = interval_values.^2;
            interval_values3 = interval_values.^3;
            
            for index = 2 : extended_number_of_points - 2
                coeffs = (1/6).*[...
                        extended_points(index - 1,:)  + 4*extended_points(index, :) + extended_points(index + 1, :); ...
                    - 3*extended_points(index - 1, :) + 3*extended_points(index + 1, :); ...
                      3*extended_points(index - 1, :) - 6*extended_points(index, :) + 3*extended_points(index + 1, :); ...
                    -   extended_points(index - 1, :) + 3*extended_points(index, :) - 3*extended_points(index + 1, :) + extended_points(index+2, :) ...
                ]';
                
                interval = [ones(size(interval_values)); interval_values; interval_values2; interval_values3];
                spline_points(:, (index - 2)*num_points + 1 : (index - 1)*num_points + 1) = coeffs*interval;
            end
        end
        
        
        
        function dicom_coordinates = PTKToDicomCoordinates(ptk_coordinates, template_image)
            offset = template_image.GetDicomOffset;
            dicom_coordinates = ptk_coordinates + repmat(offset, size(ptk_coordinates, 1), 1);
        end
        
        function [d_x, d_y, d_z] = PTKToDicomCoordinatesCoordwise(p_x, p_y, p_z, template_image)
            offset = template_image.GetDicomOffset;
            d_x = p_x + offset(1);
            d_y = p_y + offset(2);
            d_z = p_z + offset(3);
        end
        
        function ptk_coordinates = DicomToPTKCoordinates(dicom_coordinates, template_image)
            offset = template_image.GetDicomOffset;
            ptk_coordinates = dicom_coordinates - repmat(offset, size(dicom_coordinates, 1), 1);
        end
        
        function dicom_coordinates = PTKToCornerCoordinates(ptk_coordinates, template_image)
            offset = template_image.GetCornerOffset;
            dicom_coordinates = ptk_coordinates + repmat(offset, size(ptk_coordinates, 1), 1);
        end
        
        function [d_x, d_y, d_z] = PTKToCornerCoordinatesCoordwise(p_x, p_y, p_z, template_image)
            offset = template_image.GetCornerOffset;
            d_x = p_x + offset(1);
            d_y = p_y + offset(2);
            d_z = p_z + offset(3);
        end
        
        function ptk_coordinates = CornerToPTKCoordinates(corner_coordinates, template_image)
            offset = template_image.GetCornerOffset;
            ptk_coordinates = corner_coordinates - repmat(offset, size(corner_coordinates, 1), 1);
        end
        
        function [ptk_x, ptk_y, ptk_z] = CoordinatesMmToPTKCoordinates(ic, jc, kc)
            ptk_x = jc;
            ptk_y = ic;
            ptk_z = -kc;
        end
        
        function coordinates_mm = PTKCoordinatesToCoordinatesMm(ptk_coordinates)
            coordinates_mm = [ptk_coordinates(:, 2), ptk_coordinates(:, 1), - ptk_coordinates(:, 3)];
        end

        function dicom_coordinates = PTKCoordinatesToCornerCoordinates(ptk_coordinates, template_image)
            offset = template_image.GetCornerOffset;
            dicom_coordinates = ptk_coordinates + repmat(offset, size(ptk_coordinates, 1), 1);
        end
        
        function dicom_coordinates = CoordinatesMmToCornerCoordinates(ptk_coordinates, template_image)
            voxel_size = template_image.VoxelSize;
            
            % Adjust to coordinates at centre of first voxel
            offset = -voxel_size/2;
            offset = [offset(2), offset(1), -offset(3)];
            
            % Shift the global origin to the first slice of the image
            global_origin = [0, 0, 0];
            
            % Adjust to Dicom origin
            offset = offset + global_origin;
            
            dicom_coordinates = [ptk_coordinates(:, 2), ptk_coordinates(:, 1), - ptk_coordinates(:, 3)];
            dicom_coordinates = dicom_coordinates + repmat(offset, size(ptk_coordinates, 1), 1);
        end
        
        function ptk_coordinates = CornerToCoordinatesMm(dicom_coordinates, template_image)
            voxel_size = template_image.VoxelSize;
            
            offset = -voxel_size/2;
            offset = [offset(2), offset(1), -offset(3)];
            
            dicom_coordinates = dicom_coordinates - repmat(offset, size(dicom_coordinates, 1), 1);
            
            ptk_coordinates = [dicom_coordinates(:, 2), dicom_coordinates(:, 1), - dicom_coordinates(:, 3)];
        end
        
        function ptk_coordinates = ConvertToPTKCoordinates(coordinates, coordinate_system, template_image)
            switch coordinate_system
                case PTKCoordinateSystem.PTK
                    ptk_coordinates = coordinates;
                case PTKCoordinateSystem.Dicom
                    ptk_coordinates = PTKImageCoordinateUtilities.DicomToPTKCoordinates(coordinates, template_image);
                case PTKCoordinateSystem.DicomUntranslated
                    ptk_coordinates = PTKImageCoordinateUtilities.CornerToPTKCoordinates(coordinates, template_image);
                otherwise
                    reporting.Error('PTKImageCoordinateUtilities:UnsupportedCoordinateSystem', 'The coordinate system specified by parameter coordinate_system is not supported');
            end
        end

        function coordinates = ConvertFromPTKCoordinates(ptk_coordinates, coordinate_system, template_image)
            switch coordinate_system
                case PTKCoordinateSystem.PTK
                    coordinates = ptk_coordinates;
                case PTKCoordinateSystem.Dicom
                    coordinates = PTKImageCoordinateUtilities.PTKToDicomCoordinates(ptk_coordinates, template_image);
                case PTKCoordinateSystem.DicomUntranslated
                    coordinates = PTKImageCoordinateUtilities.PTKToCornerCoordinates(ptk_coordinates, template_image);
                otherwise
                    reporting.Error('PTKImageCoordinateUtilities:UnsupportedCoordinateSystem', 'The coordinate system specified by parameter coordinate_system is not supported');
            end
        end
        
        function [c_x, c_y, c_z] = ConvertFromPTKCoordinatesCoordwise(p_x, p_y, p_z, coordinate_system, template_image)
            switch coordinate_system
                case PTKCoordinateSystem.PTK
                    c_x = p_x;
                    c_y = p_y;
                    c_z = p_z;
                case PTKCoordinateSystem.Dicom
                    [c_x, c_y, c_z] = PTKImageCoordinateUtilities.PTKToDicomCoordinatesCoordwise(p_x, p_y, p_z, template_image);
                case PTKCoordinateSystem.DicomUntranslated
                    [c_x, c_y, c_z] = PTKImageCoordinateUtilities.PTKToCornerCoordinatesCoordwise(p_x, p_y, p_z, template_image);
                otherwise
                    reporting.Error('PTKImageCoordinateUtilities:UnsupportedCoordinateSystem', 'The coordinate system specified by parameter coordinate_system is not supported');
            end
        end
        
        
        function voxel_indices = AddNearestNeighbours(voxel_indices, template_image)
            if isempty(voxel_indices)
                return;
            end
            [~, linear_offsets27] = PTKImageCoordinateUtilities.GetLinearOffsets(template_image.ImageSize);
            voxel_indices = repmat(int32(voxel_indices), 27, 1) + repmat(int32(linear_offsets27'), 1, length(voxel_indices));
            voxel_indices = unique(voxel_indices(:));
        end
        
        function global_coordinates = GetGlobalCoordinatesForPoints(point_list, template_image)
            xc = [point_list.CoordX];
            yc = [point_list.CoordY];
            zc = [point_list.CoordZ];
            ptk_coords = [xc', yc', zc'];
            coordinates_mm = PTKImageCoordinateUtilities.PTKCoordinatesToCoordinatesMm(ptk_coords);
            global_coordinates = round(template_image.CoordinatesMmToGlobalCoordinates(coordinates_mm));
        end
        
        function global_indices = GetGlobalIndicesForPoints(point_list, template_image)
            global_coordinates = PTKImageCoordinateUtilities.GetGlobalCoordinatesForPoints(point_list, template_image);
            global_indices = template_image.GlobalCoordinatesToGlobalIndices(global_coordinates);
        end
        
        function dist = DistanceBetweenPoints(point_1, point_2)
            dist = norm([point_1.CoordX - point_2.CoordX, point_1.CoordY - point_2.CoordY, point_1.CoordZ - point_2.CoordZ]);
        end
    end
end

