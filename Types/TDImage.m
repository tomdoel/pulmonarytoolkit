classdef TDImage < handle
    % TDImage. A class for holding a 3D image volume.
    %
    %     TDImage is the fundamental image class used by the Pulmonary Toolkit.
    %     It stores the image data and associated metadata, such as the voxel
    %     size, and maintains the knowledge of the relationship between this
    %     image and the image it was derived from after cropping and scaling
    %     operations. This class also provides a variety of utility routines for
    %     cropping, scaling, generating thumbnail images, fast saving/loading to
    %     disk, morphological operations, and the ability to extract out
    %     subimages, modify them and reinsert them.
    %
    %     Any function which takes a TDImage as input, should also return a
    %     TDImage as output, with the metadata preserved. You can do this by
    %     creating a 'template image' using the BlankCopy() method, e.g.
    %
    %         % This function doubles the values in a TDImage
    %         function output_image = DoubleImage(input_image)
    %
    %             % Creates a template image with no data, but with metadata
    %             % matching the input image
    %             output_image = input_image.BlankCopy;
    %
    %             % Access the actual image data
    %             image_data = input_image.RawImage;
    %
    %             % Double the image data
    %             image_data = 2*image_data;
    %
    %             % Set the data for the output image
    %             output_image.ChangeRawImage(image_data);
    %         end
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties
        ImageType
        Title
    end
    
    properties (SetAccess = protected)
        RawImage = []
        VoxelSize
        Scale = [1 1 1]
        Origin = [1 1 1]
        
        CachedDataType
        CachedImageSize
        CachedRawImageFilename
        
        LastImageSize = []
        LastDataType = []
        OriginalImageSize = []
        
        Preview = []
        
        GlobalLimits
    end

    properties (Access = private)
        CachedDataIsValid = false
        CachedLimits
        ImageHasBeenSet
        
        % List of properties which should be ignored when testing equality
        % between two TDImage objects.
        PropertiesToIgnoreOnComparison = {'CachedDataType', 'LastDataType', 'CachedImageSize', ...
            'CachedRawImageFilename', ...
            'OriginalImageSize', 'CachedDataIsValid', 'CachedLimits'} 
    end
    
    % Dependent properties are not cached in memory
    properties (Dependent = true)
        Limits       % The maximum and minimum image values
        ImageSize    % The image size; remembers the last image size if this is s template image with no raw data
        ImageExists  % Whether any image data exists
    end

    events
        ImageChanged % An event to indicate if the image has changed
    end
    
    methods
        
        % Constructs a new image using raw data from new_image if specified
        function obj = TDImage(new_image, image_type, voxel_size)            
            switch nargin
                case 0
                    obj.RawImage = zeros(0, 0, 0, 'uint8');
                    obj.VoxelSize = [1, 1, 1];
                    obj.ImageType = TDImageType.Grayscale;
                    obj.OriginalImageSize = [0 0 0];
                case 1
                    obj.RawImage = new_image;
                    obj.VoxelSize = [1, 1, 1];
                    obj.ImageType = obj.GuessImageType;
                    obj.OriginalImageSize = size(new_image);
                case 2
                    obj.RawImage = new_image;
                    obj.VoxelSize = [1, 1, 1];
                    obj.ImageType = image_type;
                    obj.OriginalImageSize = size(new_image);
                case 3
                    obj.RawImage = new_image;
                    obj.VoxelSize = voxel_size;
                    obj.ImageType = image_type;
                    obj.OriginalImageSize = size(new_image);
            end
            
            obj.LastImageSize = obj.OriginalImageSize;
            obj.LastDataType = class(obj.RawImage);
        end

        % For a disk-cached image header, this loads the raw data
        function LoadRawImage(obj, file_path, reporting)
            if (nargin < 3)
                reporting = [];
            end
           
            if isempty(obj.RawImage) && ~isempty(obj.CachedRawImageFilename)
                raw_filename = obj.CachedRawImageFilename;
                full_raw_filename = fullfile(file_path, raw_filename);
                if ~exist(full_raw_filename, 'file');
                    throw(MException('TDImage:RawFileNotFound', ['The raw file ' raw_filename ' does not exist']));
                end
                
                data_type = obj.CachedDataType;
                image_size = obj.CachedImageSize;
                obj.CachedImageSize = [];
                obj.CachedDataType = [];
                obj.CachedRawImageFilename = [];
                
                if strcmp(data_type, 'logical')
                    obj.RawImage = false(image_size);
                else
                    obj.RawImage = zeros(image_size, data_type);
                end

                % Logical data is saved in bitwise format
                if strcmp(data_type, 'logical')
                    file_data_type = 'ubit1';
                else
                    file_data_type = data_type;
                end
 
                if ~isempty(reporting)
                    reporting.Log(['Loading raw image file ' full_raw_filename]);
                end
                
                fid = fopen(full_raw_filename, 'rb');
                data = fread(fid, ['*' file_data_type]);
                obj.RawImage(:) = data(1:numel(obj.RawImage(:)));
                fclose(fid);
                    
                obj.NotifyImageChangedCacheStillValid

            end
        end

        % Saves the raw image data. Optionally returns a header object which
        % contains the image object without the image data, and with the 
        % filename stored so that it can be reloaded using a call to
        % LoadRawImage
        function header_file = SaveRawImage(obj, file_path, file_name)
            data_type = class(obj.RawImage);
            raw_filename = [file_name '.raw'];

            % Create a header file if requested. The header is the image object 
            % minus the raw image data, and contains the raw image filename
            if (nargout > 0)
                header_file = obj.BlankCopy;
                
                % We cache these values in the image class so they can be retrieved
                % when loading the raw data
                header_file.CachedDataType = data_type;
                header_file.CachedImageSize = obj.ImageSize;
                header_file.CachedRawImageFilename = raw_filename;
                
            end

            % Logical data will be saved in bitwise format
            if strcmp(data_type, 'logical')
                file_data_type = 'ubit1';
            else
                file_data_type = data_type;
            end

            % Save raw image data
            full_raw_filename = fullfile(file_path, raw_filename);
            fid = fopen(full_raw_filename, 'wb');
            fwrite(fid, obj.RawImage, file_data_type);
            fclose(fid);
        end
        
        % Replaces the underlying raw image data. This function is used for
        % applying data which relates to the same original image; hence the
        % image size must be the same.
        function ChangeRawImage(obj, new_image, image_type)
            if (nargin > 2)
                obj.ImageType = image_type;
            end

            % Compare image sizes, but ignore anything beyond the first 3
            % dimensions so that we allow switching between quiver plots
            % (vectors) and scalars
            new_image_size = size(new_image);
            
            % If the length of the 3rd dimension of 'new_image' is 1, Matlab 
            % will remove that dimension from the size argument, so we need to
            % add it in so we can make a proper comparison
            if length(new_image_size) == 2
                new_image_size = [new_image_size 1];
            end
            
            if length(new_image_size) > 3
                new_image_size = new_image_size(1:3);
            end
            this_image_size = obj.ImageSize;
            if length(this_image_size) > 3
                this_image_size = this_image_size(1:3);
            end
            
            if ~isequal(this_image_size, new_image_size)
                error('The new image data must be the same size as the original data');
            end
            
            obj.RawImage = new_image;
            obj.NotifyImageChanged;
        end
        
        % Returns a raw image suitable for use with Matlab's plottin functions
        % such as isosurface. The k-direction is inverted since the orientation
        % for TDImage is is opposite to that for Matlab's 3D axes
        function raw_image = GetRawImageForPlotting(obj)
            raw_image = flipdim(obj.RawImage, 3);
        end
        
        % This function changes part of the image, as defined by the origin
        % of the subimage
        function ChangeSubImage(obj, new_subimage)
            dst_offset = new_subimage.Origin - obj.Origin + [1 1 1];
            src_offset = obj.Origin - new_subimage.Origin + [1 1 1];
            
            dst_start_crop = max(1, dst_offset);
            dst_end_crop = min(obj.ImageSize(1:3), dst_offset + new_subimage.ImageSize(1:3) - 1);
            
            src_start_crop = max(1, src_offset);
            src_end_crop = min(new_subimage.ImageSize(1:3), src_offset + obj.ImageSize(1:3) - 1);
            
            obj.RawImage(...
                    dst_start_crop(1) : dst_end_crop(1), ...
                    dst_start_crop(2) : dst_end_crop(2), ...
                    dst_start_crop(3) : dst_end_crop(3), ...
                    : ...
                )  = new_subimage.RawImage(...
                    src_start_crop(1) : src_end_crop(1), ...
                    src_start_crop(2) : src_end_crop(2), ...
                    src_start_crop(3) : src_end_crop(3), ...    
                    : ...
                );
            obj.NotifyImageChanged;
        end

        % Adjusts the image borders to match the specified template image
        function ResizeToMatch(obj, template_image)
            if obj.ImageExists
                src_offset = template_image.Origin - obj.Origin + [1 1 1];
                dst_offset = obj.Origin - template_image.Origin + [1 1 1];
                
                src_start_crop = max(1, src_offset);
                src_end_crop = min(obj.ImageSize(1:3), src_offset + template_image.ImageSize(1:3) - 1);
                
                dst_start_crop = max(1, dst_offset);
                dst_end_crop = min(template_image.ImageSize(1:3), dst_offset + obj.ImageSize(1:3) - 1);
                
                class_name = class(obj.RawImage);
                
                num_dims = length(template_image.ImageSize);
                new_image_size = obj.ImageSize;
                new_image_size(1:num_dims) = template_image.ImageSize;
                if strcmp(class_name, 'logical')
                    new_rawimage = false(new_image_size);
                else
                    new_rawimage = zeros(new_image_size, class_name);
                end
                new_rawimage(...
                    dst_start_crop(1) : dst_end_crop(1), ...
                    dst_start_crop(2) : dst_end_crop(2), ...
                    dst_start_crop(3) : dst_end_crop(3), ...
                    : )  = obj.RawImage(...
                    src_start_crop(1) : src_end_crop(1), ...
                    src_start_crop(2) : src_end_crop(2), ...
                    src_start_crop(3) : src_end_crop(3),  ...
                    : );
                obj.RawImage = new_rawimage;
            end
            obj.Origin = template_image.Origin;
            obj.NotifyImageChanged;
        end
        
        % Makes a copy of this image
        function copy = Copy(obj)
            copy = TDImage(obj.RawImage, obj.ImageType, obj.VoxelSize);
            metaclass = ?TDImage;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list);
                property = property_list{i};
                if (~property.Dependent) && (~property.Constant)
                    copy.(property.Name) = obj.(property.Name);
                end
            end
        end
        
        % This function creates an empty template image, i.e. a copy with
        % all the fields set up but with no actual image data
        function copy = BlankCopy(obj)
            copy = TDImage([], obj.ImageType, obj.VoxelSize);
            metaclass = ?TDImage;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list);
                property = property_list{i};
                if (~property.Dependent) && (~property.Constant) && (~strcmp(property.Name, 'RawImage'))
                    copy.(property.Name) = obj.(property.Name);
                end
            end
        end
        
        % Downscales the image so that it is below the specified value in all
        % dimensions
        function RescaleToMaxSize(obj, max_size)
            scale = [1 1 1];
            image_size = obj.ImageSize;
            original_image_size = image_size;
            for dim_index = 1 : 3
                while image_size(dim_index) > max_size
                    scale(dim_index) = scale(dim_index) + 1;
                    image_size = floor(original_image_size./scale);
                end
            end
            
            obj.VoxelSize = scale.*obj.VoxelSize;
            obj.Scale = scale;
            obj.RawImage = obj.RawImage(1:scale(1):end, 1:scale(2):end, 1:scale(3):end);
            obj.NotifyImageChanged;
        end
        
        % Returns a 2D slice from the image in the specified direction
        function slice = GetSlice(obj, slice_number, dimension)
           switch dimension
               case TDImageOrientation.Coronal
                   slice = squeeze(obj.RawImage(slice_number, :, :));
               case TDImageOrientation.Sagittal
                   slice = squeeze(obj.RawImage(:, slice_number, :));
               case TDImageOrientation.Axial
                   slice = squeeze(obj.RawImage(:, :, slice_number));
               otherwise
                   error('Unsupported dimension');
           end
        end
        
        function image_size = get.ImageSize(obj)
            if isempty(obj.RawImage)
               image_size = obj.LastImageSize;
            else
                image_size = size(obj.RawImage);
            end
            if isempty(image_size)
                image_size = [0, 0, 0];
            end
            
            while length(image_size) < 3
                image_size = [image_size 1];
            end
        end
        
        function exists = get.ImageExists(obj)
            exists = ~isempty(obj.RawImage);
        end
        
        % Returns the image limits
        function limits = get.Limits(obj)
            if obj.CachedDataIsValid
                limits = obj.CachedLimits;
            else
                limits = [min(obj.RawImage(:)), max(obj.RawImage(:))];
                obj.CachedLimits = limits;
                obj.CachedDataIsValid = true;
            end
        end

        function value = GetValue(obj, coords)
           value = obj.RawImage(coords(1), coords(2), coords(3)); 
        end

        function [value units] = GetRescaledValue(obj, ~)
            value = [];
            units = [];
        end

        function point_is_in_image = IsPointInImage(obj, coord)
            image_size = obj.ImageSize;
            i_in_image = (coord(1) > 0) && (coord(1) <= image_size(1));
            j_in_image = (coord(2) > 0) && (coord(2) <= image_size(2));
            k_in_image = (coord(3) > 0) && (coord(3) <= image_size(3));
            point_is_in_image = i_in_image && j_in_image && k_in_image;
        end
        
        % Changes the value of the voxel specified by image coordinates
        function SetVoxelToThis(obj, coord, value)
            obj.RawImage(coord(1), coord(2), coord(3)) = value;
            obj.NotifyImageChanged;
        end

        % Changes the value of the voxel specified by an index value
        function SetIndexedVoxelsToThis(obj, voxel_indices, value)            
            obj.RawImage(voxel_indices) = value;
            obj.NotifyImageChanged;
        end

        % Sets all image values to zero
        function Clear(obj)
            obj.RawImage(:) = 0;
            obj.NotifyImageChanged;
        end

        % Deletes the image
        function Reset(obj)
            obj.RawImage = [];
            obj.NotifyImageChanged;
        end

        % Creates an image projection in the specified direction
        function Flatten(obj, direction)
            flat = max(obj.RawImage, [], direction);
            number_of_repeats = size(obj.RawImage, direction);
            switch direction
                case TDImageOrientation.Coronal
                    obj.RawImage = repmat(flat, [number_of_repeats 1 1]);
                case TDImageOrientation.Sagittal
                    obj.RawImage = repmat(flat, [1 number_of_repeats 1]);
                case TDImageOrientation.Axial
                    obj.RawImage = repmat(flat, [1 1 number_of_repeats]);
            end
            obj.NotifyImageChanged;
        end
        
        % Modifies the specified 2D slice of the image
        function ReplaceImageSlice(obj, new_slice, slice_index, direction)
            switch direction
                case TDImageOrientation.Coronal
                    obj.RawImage(slice_index, :, :) = new_slice;
                case TDImageOrientation.Sagittal
                    obj.RawImage(:, slice_index, :) = new_slice;
                case TDImageOrientation.Axial
                    obj.RawImage(:, :, slice_index) = new_slice;
            end
            obj.NotifyImageChanged;
        end
        
        % Removes surrounding zeros; i.e. strips away planes of
        % zeros from the edges of the image
        function CropToFit(obj)
            if obj.ImageExists
                
                i_min = find(any(any(obj.RawImage, 2), 3), 1, 'first');
                i_max = find(any(any(obj.RawImage, 2), 3), 1, 'last' );
                
                j_min = find(any(any(obj.RawImage, 1), 3), 1, 'first');
                j_max = find(any(any(obj.RawImage, 1), 3), 1, 'last' );
                
                k_min = find(any(any(obj.RawImage, 1), 2), 1, 'first');
                k_max = find(any(any(obj.RawImage, 1), 2), 1, 'last' );
                
                % Create new image
                obj.RawImage = obj.RawImage(i_min:i_max, j_min:j_max, k_min:k_max);
                
                obj.Origin = obj.Origin + [i_min - 1, j_min - 1, k_min - 1];
                obj.NotifyImageChanged;
            end
        end
        
        % Strips away a border around the image, returning the region specified
        % by start_crop and end_crop
        function Crop(obj, start_crop, end_crop)
            if obj.ImageExists
                obj.RawImage = obj.RawImage(start_crop(1):end_crop(1), start_crop(2):end_crop(2), start_crop(3):end_crop(3));
                obj.Origin = obj.Origin + [start_crop(1) - 1, start_crop(2) - 1, start_crop(3) - 1];
                obj.NotifyImageChanged;
            end
        end
        
        % Adds a blank border of border_size voxels to the image in all
        % dimensions
        function AddBorder(obj, border_size)
            if ~isempty(obj.RawImage)
                added_size = [border_size border_size border_size];
                class_name = class(obj.RawImage);
                if strcmp(class_name, 'logical')
                    new_image = false(obj.ImageSize + 2*added_size);
                else
                    new_image = zeros(obj.ImageSize + 2*added_size, class_name);
                end
                
                new_image(1+border_size:end-border_size, 1+border_size:end-border_size, 1+border_size:end-border_size) = obj.RawImage;
                obj.RawImage = new_image;
                obj.Origin = obj.Origin - added_size;
                obj.NotifyImageChanged;
            end
        end
        
        % Removes a border of border_size voxels to the image in all dimensions
        function RemoveBorder(obj, border_size)
            if obj.ImageExists
                added_size = [border_size border_size border_size];
                obj.RawImage = obj.RawImage(1+border_size : end-border_size, 1+border_size : end-border_size, 1+border_size : end-border_size);
                obj.Origin = obj.Origin + added_size;
                obj.NotifyImageChanged;
            end
        end
        
        % Performs a Matlab morphological operation using s apherical element of
        % the specified size in mm, adjusting for the voxel size
        function Morph(obj, morph_function_handle, size_mm)
            % Create structural element as a ball shape
            ball_element = obj.CreateBallStructuralElement(size_mm);
            
            obj.RawImage = uint8(morph_function_handle(obj.RawImage, ball_element));
            obj.NotifyImageChanged;
        end

        % Performs a Matlab morphological operation using s apherical element of
        % the specified size in mm, adjusting for the voxel size
        function BinaryMorph(obj, morph_function_handle, size_mm)
            % Create structural element as a ball shape
            ball_element = obj.CreateBallStructuralElement(size_mm);
            
            obj.RawImage = obj.RawImage > 0;
            obj.RawImage = uint8(morph_function_handle(obj.RawImage, ball_element));
            obj.NotifyImageChanged;
        end
        
        % Performs a Matlab morphological operation as above, but first adds an additional boder to the image
        function MorphWithBorder(obj, morph_function_handle, size_mm)
            % Create structural element as a ball shape
            ball_element = obj.CreateBallStructuralElement(size_mm);
            borders = size(ball_element);
            image_size_with_borders = obj.ImageSize + 2*borders;
            morphed_image = false(image_size_with_borders);
            start_pos = borders + 1;
            end_pos = image_size_with_borders - borders;
            morphed_image(start_pos(1):end_pos(1), start_pos(2):end_pos(2), start_pos(3):end_pos(3)) = obj.RawImage > 0;
            
            morphed_image = uint8(morph_function_handle(morphed_image, ball_element));
            obj.RawImage = uint8(morphed_image(start_pos(1):end_pos(1), start_pos(2):end_pos(2), start_pos(3):end_pos(3)));
            obj.NotifyImageChanged;
        end
        
        % Creates a thumbnail preview image
        function GeneratePreview(obj, preview_size, flatten_before_preview)
            slice_position = round(obj.ImageSize(1)/2);

            if flatten_before_preview
                image_copy = obj.Copy;
                image_copy.Flatten(TDImageOrientation.Coronal);
                slice = image_copy.GetSlice(slice_position, TDImageOrientation.Coronal);
            else
                slice = obj.GetSlice(slice_position, TDImageOrientation.Coronal); 
            end
            slice = slice';

            image_slice_size = obj.ImageSize([3, 2]);
            image_slice_voxelsize = obj.VoxelSize([3, 2]);
            
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

            obj.Preview = obj.BlankCopy;
            obj.Preview.RawImage = zeros(preview_size);
            gap = preview_size - scaled_preview_size;
            startpos = 1 + floor(gap/2);
            endpos = startpos + scaled_preview_size - [1 1];
                        
            switch obj.ImageType
                case TDImageType.Grayscale
                    method = 'cubic';
                case TDImageType.Colormap
                    method = 'nearest';
                    nn_grid_size = 1./preview_scale;
                    floor_scale = max(1, ceil(nn_grid_size/2));
                    domain = true(floor_scale);
                    slice = ordfilt2(double(slice), numel(domain), domain);
                case TDImageType.Scaled
                    method = 'nearest';
                    nn_grid_size = 1./preview_scale;
                    floor_scale = max(1, ceil(nn_grid_size/2));
                    domain = true(floor_scale);
                    slice = ordfilt2(slice, numel(domain), domain);
                otherwise
                    method = 'cubic';                    
            end
            
            obj.Preview.RawImage(startpos(1):endpos(1), startpos(2):endpos(2)) = imresize(double(slice), scaled_preview_size, method);

            obj.Preview.Scale = [preview_scale, preview_scale];
            obj.Preview.GlobalLimits = obj.Limits;
        end
        
        % Equality operator
        function is_equal = eq(obj, other)
            metaclass = ?TDImage;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list);
                property = property_list{i};
                if (~property.Dependent) && (~ismember(property.Name, obj.PropertiesToIgnoreOnComparison))
                    if ~isequal(other.(property.Name), obj.(property.Name))
                        is_equal = false;
                        return;
                    end
                end
            end
            is_equal = true;
        end
        
        function global_coords = LocalToGlobalCoordinates(obj, coords)
            global_coords = obj.Origin + coords - [1, 1, 1];
        end
        
        function local_coords = GlobalToLocalCoordinates(obj, global_coords)
            local_coords = global_coords - obj.Origin + [1, 1, 1];
        end
        
        function global_indices = LocalToGlobalIndices(obj, local_indices)
            global_indices = TDImageCoordinateUtilities.OffsetIndices(local_indices, obj.Origin - [1, 1, 1], obj.ImageSize, obj.OriginalImageSize);
        end
        
        function local_indices = GlobalToLocalIndices(obj, global_indices)
            local_indices = TDImageCoordinateUtilities.OffsetIndices(global_indices, [1, 1, 1] - obj.Origin, obj.OriginalImageSize, obj.ImageSize);
        end
        
    end
    
    methods (Access = private)
        
        % This method should be called whenever the raw image is changed
        function NotifyImageChanged(obj)
            obj.InvalidateCachedData;
            obj.NotifyImageChangedCacheStillValid
        end
        
        % This method is called when the raw image has changed
        function NotifyImageChangedCacheStillValid(obj)
            obj.InvalidateCachedData;
            if ~isempty(obj.RawImage)
                obj.LastImageSize = size(obj.RawImage);
                obj.LastDataType = class(obj.RawImage);
            end
            notify(obj, 'ImageChanged');
        end
        
        function InvalidateCachedData(obj)
            obj.CachedDataIsValid = false;
        end
        
        function ball_element = CreateBallStructuralElement(obj, size_mm)
            voxel_size = obj.VoxelSize;
            strel_size_voxels = ceil(size_mm./(2*voxel_size));
            ispan = -strel_size_voxels(1) : strel_size_voxels(1);
            jspan = -strel_size_voxels(2) : strel_size_voxels(2);
            kspan = -strel_size_voxels(3) : strel_size_voxels(3);
            [i, j, k] = ndgrid(ispan, jspan, kspan);
            i = i.*voxel_size(1);
            j = j.*voxel_size(2);
            k = k.*voxel_size(3);
            ball_element = zeros(size(i));
            ball_element(:) = sqrt(i(:).^2 + j(:).^2 + k(:).^2);
            ball_element = ball_element <= (size_mm/2);
        end
        
        
        function image_type = GuessImageType(obj)
            class_name = class(obj.RawImage);
            if strcmp(class_name, 'logical')
                image_type = TDImageType.Colormap;
            elseif strcmp(class_name, 'uint8')
                image_type = TDImageType.Colormap;
            elseif strcmp(class_name, 'int8')
                image_type = TDImageType.Colormap;
            else
                image_type = TDImageType.Grayscale;
            end
        end
    end
        
end