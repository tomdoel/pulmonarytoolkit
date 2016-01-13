classdef PTKImageUtilities
    % PTKImageCoordinateUtilities. Utility functions related to displaying images
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
        
    methods (Static)
        
        % Rescale image to a single-byte in the range 0-255.
        function rescaled_image = RescaleImage(image, window, level)
            min_value = double(level) - double(window)/2;
            max_value = double(level) + double(window)/2;
            scale_factor = 255/(max_value - min_value);
            rescaled_image = uint8(min(((image - min_value)*scale_factor), 255));
        end  
        
        % Draws box lines around a point in all dimensions, to emphasize that
        % point. Used by the show trachea plugin.
        function image = DrawBoxAround(image, centre_point, box_size, colour)
            if length(box_size) == 1
                box_size = [box_size, box_size, box_size];
            end

            min_coords = max(centre_point - box_size, 1);
            max_coords = min(centre_point + box_size, size(image));

            image(min_coords(1):max_coords(1), min_coords(2), centre_point(3)) = colour;
            image(min_coords(1):max_coords(1), max_coords(2), centre_point(3)) = colour;
            image(min_coords(1), min_coords(2):max_coords(2), centre_point(3)) = colour;
            image(max_coords(1), min_coords(2):max_coords(2), centre_point(3)) = colour;
            
            image(centre_point(1), min_coords(2), min_coords(3):max_coords(3)) = colour;
            image(centre_point(1), max_coords(2), min_coords(3):max_coords(3)) = colour;
            image(centre_point(1), min_coords(2):max_coords(2), min_coords(3)) = colour;
            image(centre_point(1), min_coords(2):max_coords(2), max_coords(3)) = colour;
            
            image(min_coords(1), centre_point(2), min_coords(3):max_coords(3)) = colour;
            image(max_coords(1), centre_point(2), min_coords(3):max_coords(3)) = colour;
            image(min_coords(1):max_coords(1), centre_point(2), min_coords(3)) = colour;
            image(min_coords(1):max_coords(1), centre_point(2), max_coords(3)) = colour;
        end
        
        % Construct a new image of zeros or logical false, depending on the
        % image class.
        function new_image = Zeros(image_size, image_class)
            if strcmp(image_class, 'logical')
                new_image = false(image_size);
            else
                new_image = zeros(image_size, image_class);
            end
        end
        
        
        function [offset_indices, ball] = GetBallOffsetIndices(voxel_size, size_mm, image_size)
            ball = CoreImageUtilities.CreateBallStructuralElement(voxel_size, size_mm);
            ball_indices = find(ball);
            central_coord = 1 + round(size(ball) - 1)/2;
            indices_big = PTKImageCoordinateUtilities.OffsetIndices(ball_indices, [0 0 0], size(ball), image_size); %#ok<FNDSB>
            central_index_big = sub2ind(image_size, central_coord(1), central_coord(2), central_coord(3));
            offset_indices = indices_big - central_index_big;
        end
        
        function image_to_invert = InvertImage(image_to_invert)
            image_to_invert.ChangeRawImage(image_to_invert.Limits(2) - image_to_invert.RawImage);
        end
        
        function MatchSizes(image_1, image_2)
            new_size = max(image_1.ImageSize, image_2.ImageSize);
            new_origin_1 = image_1.Origin - floor((new_size - image_1.ImageSize)/2);
            image_1.ResizeToMatchOriginAndSize(new_origin_1, new_size);
            new_origin_2 = image_2.Origin - floor((new_size - image_2.ImageSize)/2);
            image_2.ResizeToMatchOriginAndSize(new_origin_2, new_size);
        end
        
        function MatchSizesAndOrigin(image_1, image_2)
            new_origin = min(image_1.Origin, image_2.Origin);
            new_size = max(image_1.Origin + image_1.ImageSize, image_2.Origin + image_2.ImageSize) - new_origin;
            image_1.ResizeToMatchOriginAndSize(new_origin, new_size);
            image_2.ResizeToMatchOriginAndSize(new_origin, new_size);
        end
        
        function combined_image = CombineImages(image_1, image_2)
            combined_image = image_1.Copy;
            new_origin = min(image_1.Origin, image_2.Origin);
            br_coords = max(image_1.Origin + image_1.ImageSize - [1,1,1], image_2.Origin + image_2.ImageSize - [1,1,1]);
            new_size = br_coords - new_origin + [1,1,1];
            combined_image.ResizeToMatchOriginAndSize(new_origin, new_size);
            combined_image.ChangeSubImage(image_2);
        end
        
        function dt = GetNormalisedDT(seg)
            seg_raw = single(bwdist(seg.RawImage == 0)); 
            max_val = single(max(seg_raw(:)));
            seg_raw = seg_raw/max_val;
            dt = seg.BlankCopy;
            dt.ChangeRawImage(seg_raw);
            dt.ImageType = PTKImageType.Scaled;
        end

        function [dt, border_image] = GetBorderDistanceTransformBySlice(image_mask, direction)
            border_image = image_mask.Copy;
            dt = image_mask.BlankCopy;
            
            % Slice by slice replace the dt image with a 2D distance transform
            for slice_index = 1 : image_mask.ImageSize(direction)
                slice = image_mask.GetSlice(slice_index, direction);
                surface_slice = PTKImageUtilities.GetSurfaceFrom2DSegmentation(slice);
                border_image.ReplaceImageSlice(surface_slice, slice_index, direction);
                dt_slice = bwdist(surface_slice > 0);
                dt.ReplaceImageSlice(dt_slice, slice_index, direction);
            end
            
            border_image.ChangeRawImage(border_image.RawImage > 0);
        end

        function segmentation_2d = GetSurfaceFrom2DSegmentation(segmentation_2d)
            segmentation_2d = int8(segmentation_2d == 1);
            
            % Find pixels that are nonzero and do not have 6 nonzero neighbours
            filter = zeros(3, 3);
            filter(:) = [0 1 0 1 0 1 0 1 0];
            image_conv = convn(segmentation_2d, filter, 'same');
            segmentation_2d = (segmentation_2d & (image_conv < 4));
        end
        
        % Resamples the image by inserting additional slices in one or more
        % directions so that the image is approximately isotropic. The original
        % image data is unchanged, and the new slices are determined by
        % interpolation
        function reference_image_resampled = MakeImageApproximatelyIsotropic(reference_image, interpolation_type)
            
            % Find a voxel size to use for the registration image. We divide up thick
            % slices to give an approximately isotropic voxel size
            register_voxel_size = reference_image.VoxelSize;
            register_voxel_size = register_voxel_size./round(register_voxel_size/min(register_voxel_size));
            
            % Resample both images so they have the same image and voxel size
            reference_image_resampled = reference_image.Copy;
            
            if strcmp(interpolation_type, 'PTK smoothed binary')
                reference_image_resampled.ResampleBinary(register_voxel_size);
            else
                reference_image_resampled.Resample(register_voxel_size, interpolation_type);
            end
        end

        % Calculates an approximate distance transform for a non-isotropic input
        % image
        function dt = GetNonisotropicDistanceTransform(binary_image)
            voxel_size = binary_image.VoxelSize;
            if max(voxel_size) >= 1.5*min(voxel_size)
                dt = PTKImageUtilities.MakeImageApproximatelyIsotropic(binary_image, '*nearest');
                dt.ChangeRawImage(bwdist(logical(dt.RawImage)));
                dt.Resample(binary_image.VoxelSize, '*nearest');
                dt.ResizeToMatch(binary_image);
            else
                dt = binary_image.Copy;
                dt.ChangeRawImage(bwdist(logical(dt.RawImage)));
            end
            dt.ImageType = PTKImageType.Scaled;
        end

        function [results, combined_image] = ComputeDice(image_1, image_2)
            PTKImageUtilities.MatchSizes(image_1, image_2);
            
            combined_image = image_1.BlankCopy;
            
            combined_image_raw = zeros(combined_image.ImageSize, 'uint8');
            
            volume_indices = find(image_1.RawImage);
            combined_image_raw(volume_indices) = 1;
            
            volume_indices = find(image_2.RawImage);
            combined_image_raw(volume_indices) = combined_image_raw(volume_indices) + 2;
            
            TP = sum(sum(sum(combined_image_raw == 3)));
            FN = sum(sum(sum(combined_image_raw == 1)));
            FP = sum(sum(sum(combined_image_raw == 2)));
            results = [];
            results.Dice = 2*TP/(2*TP+FP+FN);
            results.Precision = TP/(TP+FP);
            results.Recall = TP/(TP+FN);
            combined_image.ChangeRawImage(combined_image_raw);
        end
        
        function [dice, combined_image] = ComputeDiceWithCoronalAllowance(image_1, image_2)
            PTKImageUtilities.MatchSizes(image_1, image_2);
            
            combined_image = image_1.BlankCopy;
            
            combined_image_raw = zeros(combined_image.ImageSize, 'uint8');
            
            volume_indices = find(image_1.RawImage);
            combined_image_raw(volume_indices) = 1;
            
            volume_indices = find(image_2.RawImage);
            combined_image_raw(volume_indices) = combined_image_raw(volume_indices) + 2;
            
            for coronal_index = 1 : image_1.ImageSize(1)
                slice = combined_image_raw(coronal_index, :, :);
                slice2 = convn(slice == 3, ones(3,3), 'same');
                slice2 = slice2 & (slice > 0);
                slice(slice2) = 3;
                combined_image_raw(coronal_index, :, :) = slice;
            end
            
            TP = sum(sum(sum(combined_image_raw == 3)));
            FN = sum(sum(sum(combined_image_raw == 1)));
            FP = sum(sum(sum(combined_image_raw == 2)));
            dice = 2*TP/(2*TP+FP+FN);
            combined_image.ChangeRawImage(combined_image_raw);
        end
        
        function results = ComputeBorderError(image_1, image_2)
            
            image_1 = image_1.Copy;
            image_1.ChangeRawImage(image_1.RawImage > 0);
            
            image_2 = image_2.Copy;
            image_2.ChangeRawImage(image_2.RawImage > 0);
            
            % Compute the in-plane resolution of the image
            voxel_length = image_1.VoxelSize(2);
            if image_1.VoxelSize(2) ~= image_1.VoxelSize(3)
                error;
            end
            
            % Get the distance transforms
            [~, border_1] = PTKImageUtilities.GetBorderDistanceTransformBySlice(image_1, PTKImageOrientation.Coronal);
            [~, border_2] = PTKImageUtilities.GetBorderDistanceTransformBySlice(image_2, PTKImageOrientation.Coronal);
            
            dt_1 = PTKImageUtilities.GetNonisotropicDistanceTransform(border_1);
            dt_2 = PTKImageUtilities.GetNonisotropicDistanceTransform(border_2);
            
            
            % Adjust the distance transforms to mm
            dt_1.ChangeRawImage(dt_1.RawImage*voxel_length);
            dt_2.ChangeRawImage(dt_2.RawImage*voxel_length);
            
            results = [];
            
            surface_distance_1 = dt_2.RawImage(border_1.RawImage);
            results.MeanDistanceFrom1To2 = mean(surface_distance_1);
            results.MaxDistanceFrom1To2 = max(surface_distance_1);

            surface_distance_2 = dt_1.RawImage(border_2.RawImage);
            results.MeanDistanceFrom2To1 = mean(surface_distance_2);
            results.MaxDistanceFrom2To1 = max(surface_distance_2);            

            combined_surface_distance = [surface_distance_1; surface_distance_2];
            mean_c = mean(combined_surface_distance);
            max_c = max(combined_surface_distance);
            
            results.MeanDistanceCombined = mean_c;
            results.MaxDistanceCombined = max_c;
        end
        
        function rgb_image = GetButtonImage(image_preview, button_width, button_height, window_hu, level_hu, border, background_colour, border_colour)
            if ~isempty(image_preview)
                if islogical(image_preview.RawImage)
                    button_image = zeros(button_height, button_width, 'uint8');
                else
                    button_image = zeros(button_height, button_width, class(image_preview.RawImage));
                end
                
                max_height = min(button_height, image_preview.ImageSize(1));
                max_width = min(button_width, image_preview.ImageSize(2));
                
                button_image(1:max_height, 1:max_width) = image_preview.RawImage(1:max_height, 1:max_width);
                image_type = image_preview.ImageType;
                image_preview_limits = image_preview.GlobalLimits;
                
                % Convert window and level from HU to greyscale values
                level_grayscale = image_preview.RescaledToGrayscale(level_hu);
                window_grayscale = window_hu;
                if isa(image_preview, 'PTKDicomImage')
                    if image_preview.IsCT && ~isempty(image_preview.RescaleSlope)
                        window_grayscale = window_grayscale/image_preview.RescaleSlope;
                    end
                end
                
            else
                button_image = zeros(button_height, button_width, 'uint8');
                image_type = PTKImageType.Colormap;
                image_preview_limits = [];
                
                level_grayscale = level_hu;
                window_grayscale = window_hu;
            end
            
            if (image_type == 3) && isempty(image_preview_limits)
                obj.Reporting.ShowWarning('PTKImageUtilities:ForcingImageLimits', ('Using default values for displaying button previews for scaled images, because I am umable to find the correct limits.'), []);
                image_preview_limits = [1 100];
            end
            
            [rgb_image, ~] = PTKImageUtilities.GetImage(button_image, image_preview_limits, image_type, window_grayscale, level_grayscale, []);
            rgb_image = GemUtilities.ConvertImageToButtonImage(border, background_colour, border_colour, button_image, rgb_image);
        end


        function [rgbSlice, alphaSlice] = GetImage(imageSlice, limits, imageType, window, level, map)
            % Returns a 2D image slice and alpha information
            
            switch imageType
                case PTKImageType.Grayscale
                    rescaled_image_slice = PTKImageUtilities.RescaleImage(imageSlice, window, level);
                    [rgbSlice, alphaSlice] = CoreImageUtilities.GetBWImage(rescaled_image_slice);
                case PTKImageType.Colormap
                    [rgbSlice, alphaSlice] = CoreImageUtilities.GetLabeledImage(imageSlice, map);
                case PTKImageType.Scaled
                    [rgbSlice, alphaSlice] = CoreImageUtilities.GetColourMap(imageSlice, limits);
            end            
        end
        
        function orientation = GetPreferredOrientation(image_template, default_orientation)
            
            % Get the image dimensions
            image_size = image_template.OriginalImageSize;
            if numel(image_size) < 3
                image_size = [image_size, 1];
            end
            
            % For a 2D image we always choose the plane of the image
            if sum(image_size == 1)
                [~, orientation_dir] = find(image_size == 1, 1);
                orientation = PTKImageOrientation(orientation_dir);
                return;
            end
           
            % If one of the voxel dimensions is smaller or larger than the
            % others, then we set this to be the orientation
            voxel_size = image_template.VoxelSize;
            [ordered_voxel_size, ordered_voxel_size_indices] = sort(voxel_size);
            if ordered_voxel_size(3)/ordered_voxel_size(1) > 2
                if ordered_voxel_size(3)/ordered_voxel_size(2) > 2
                    orientation = PTKImageOrientation(ordered_voxel_size_indices(3));
                else
                    orientation = PTKImageOrientation(ordered_voxel_size_indices(1));
                end
                return
            end

            % If the voxel dimensions are roughly similar then we look at
            % the image dimensions. If one dimension is much smaller or
            % larger than the others then we set this to be the orientation
            [ordered_image_size, ordered_image_size_indices] = sort(image_size);
            if ordered_image_size(3)/ordered_image_size(1) > 5
                if ordered_image_size(3)/ordered_image_size(2) > 5
                    orientation = PTKImageOrientation(ordered_image_size_indices(3));
                else
                    orientation = PTKImageOrientation(ordered_image_size_indices(1));
                end
                return
            end
            
            % Otherwise we choose the default
            orientation = default_orientation;
        end
        
        function is_signed = IsSigned(image_object)
            % Returns true if the image datatype is signed
            
            switch class(image_object.RawImage(1))
                case {'uint8', 'uint16', 'uint32', 'uint64'}
                    is_signed = false;
                otherwise
                    is_signed = true;
            end
        end
        
        function binary_image = GetLargestConnectedComponent(binary_image)
            cc = bwconncomp(binary_image);
            num_pixels = cellfun(@numel, cc.PixelIdxList);
            [~, largest_component_index] = max(num_pixels);
            binary_image(:) = false;
            binary_image(cc.PixelIdxList{largest_component_index}) = true;
        end
        
        function original_image = HighlightRGBImage(original_image, background_colour)
            image_dilated = PTKImageUtilities.GetRGBImageHighlight(original_image, background_colour);
            highlight_colour = [255, 255, 0];
            for index = 1 : 3
                image_layer = original_image(:, :, index);
                image_layer(image_dilated) = highlight_colour(index);
                original_image(:, :, index) = image_layer;
            end
        end
        
        function [preview_image_slice, preview_scale] = GeneratePreviewImage(image, preview_size, flatten_before_preview)
            
            % Creates a thumbnail preview image
            
            slice_position = round(image.ImageSize(1)/2);

            if flatten_before_preview
                image_copy = image.Copy;
                image_copy.Flatten(PTKImageOrientation.Coronal);
                slice = image_copy.GetSlice(slice_position, PTKImageOrientation.Coronal);
            else
                slice = image.GetSlice(slice_position, PTKImageOrientation.Coronal); 
            end
            slice = slice';

            image_slice_size = image.ImageSize([3, 2]);
            image_slice_voxelsize = image.VoxelSize([3, 2]);
            
            image_slice_size_mm = image_slice_size.*image_slice_voxelsize;
            
            [~, largest_direction] = max(image_slice_size_mm./preview_size);
            other_direction = setxor([1 2], largest_direction);
            
            preview_scale = preview_size(largest_direction)/image_slice_size_mm(largest_direction);
            scaled_preview_size = zeros(1, 2);
            scaled_preview_size(largest_direction) = preview_size(largest_direction);
            scaled_preview_size(other_direction) = preview_scale*image_slice_size_mm(other_direction);
            scaled_preview_size = ceil(scaled_preview_size);
            scaled_preview_size = max(1, scaled_preview_size);
            scaled_preview_size = min(preview_size, scaled_preview_size);

            gap = preview_size - scaled_preview_size;
            startpos = 1 + floor(gap/2);
            endpos = startpos + scaled_preview_size - [1 1];
                        
            switch image.ImageType
                case PTKImageType.Grayscale
                    method = 'cubic';
                case PTKImageType.Colormap
                    method = 'nearest';
                    nn_grid_size = 1./preview_scale;
                    floor_scale = max(1, ceil(nn_grid_size/2));
                    domain = true(floor_scale);
                    slice = ordfilt2(double(slice), numel(domain), domain);
                case PTKImageType.Scaled
                    method = 'nearest';
                    nn_grid_size = 1./preview_scale;
                    floor_scale = max(1, ceil(nn_grid_size/2));
                    domain = true(floor_scale);
                    slice = ordfilt2(slice, numel(domain), domain);
                otherwise
                    method = 'cubic';                    
            end
            
            preview_image_slice = zeros(preview_size);
            preview_image_slice(startpos(1):endpos(1), startpos(2):endpos(2)) = imresize(double(slice), scaled_preview_size, method);
        end  
        
        function best_series = FindBestSeries(datasets)
            modalities = CoreContainerUtilities.GetFieldValuesFromSet(datasets, 'Modality');

            if isempty(modalities) || ~iscellstr(modalities)
                selected_datasets = datasets;
            else
                matches_modality = ismember(modalities, 'CT') | ismember(modalities, 'MR');
                selected_datasets = datasets(matches_modality);
            end
            num_images = CoreContainerUtilities.GetMatrixOfFieldValuesFromSet(selected_datasets, 'NumberOfImages');
            [~, max_index] = max(num_images);
            best_series = selected_datasets{max_index}.SeriesUid;
        end
        
    end
end

