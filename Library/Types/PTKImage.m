classdef (ConstructOnLoad = true) PTKImage < handle
    % PTKImage. A class for holding a 3D image volume.
    %
    %     PTKImage is the fundamental image class used by the Pulmonary Toolkit.
    %     It stores the image data and associated metadata, such as the voxel
    %     size, and maintains the knowledge of the relationship between this
    %     image and the image it was derived from after cropping and scaling
    %     operations. This class also provides a variety of utility routines for
    %     cropping, scaling, generating thumbnail images, fast saving/loading to
    %     disk, morphological operations, and the ability to extract out
    %     subimages, modify them and reinsert them.
    %
    %     Any function which takes a PTKImage as input, should also return a
    %     PTKImage as output, with the metadata preserved. You can do this by
    %     creating a 'template image' using the BlankCopy() method, e.g.
    %
    %         % This function doubles the values in a PTKImage
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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties (SetObservable)
        ImageType
        Title
        GlobalOrigin = [0 0 0] % Stored as IJK (ie YXZ)
    end
    
    properties (SetAccess = protected)
        RawImage = []
        VoxelSize
        Scale = [1 1 1]
        Origin = [1 1 1]
        
        CachedDataType
        CachedImageSize
        CachedRawImageFilename
        CachedRawImageCompression
        
        LastImageSize = []
        LastDataType = []
        OriginalImageSize = []
        
        Preview = []
        
        GlobalLimits
        
        ColorLabelMap
        ColourLabelChildMap
        ColourLabelParentMap
    end

    properties (Access = private)
        CachedDataIsValid = false
        CachedLimits
        ImageHasBeenSet
        
        % List of properties which should be ignored when testing equality
        % between two PTKImage objects.
        PropertiesToIgnoreOnComparison = {'CachedDataType', 'LastDataType', 'CachedImageSize', ...
            'CachedRawImageFilename', 'CachedRawImageCompression', ...
            'OriginalImageSize', 'CachedDataIsValid', 'CachedLimits'} 
    end
    
    % Dependent properties are not cached in memory
    properties (Dependent = true)
        Limits       % The maximum and minimum image values
        ImageSize    % The image size; remembers the last image size if this is a template image with no raw data
        ImageExists  % Whether any image data exists
    end

    events
        ImageChanged % An event to indicate if the image has changed
    end
    
    methods    
        function obj = PTKImage(new_image, image_type, voxel_size)            
            % Constructs a new image using raw data from new_image if specified
            if nargin > 0
                if isstruct(new_image)
                    error('First argument must be an image');
                end
            end
            switch nargin
                case 0
                    obj.RawImage = zeros(0, 0, 0, 'uint8');
                    obj.VoxelSize = [1, 1, 1];
                    obj.ImageType = PTKImageType.Grayscale;
                    obj.OriginalImageSize = [0 0 0];
                case 1
                    if isa(new_image, 'CoreWrapper')
                        obj.RawImage = new_image.RawImage;
                    else
                        obj.RawImage = new_image;
                    end
                    obj.VoxelSize = [1, 1, 1];
                    obj.ImageType = obj.GuessImageType;
                    obj.OriginalImageSize = size(new_image);
                case 2
                    if isa(new_image, 'CoreWrapper')
                        obj.RawImage = new_image.RawImage;
                    else
                        obj.RawImage = new_image;
                    end
                    obj.VoxelSize = [1, 1, 1];
                    obj.ImageType = image_type;
                    obj.OriginalImageSize = size(new_image);
                case 3
                    if isa(new_image, 'CoreWrapper')
                        obj.RawImage = new_image.RawImage;
                    else
                        obj.RawImage = new_image;
                    end
                    obj.VoxelSize = voxel_size;
                    obj.ImageType = image_type;
                    obj.OriginalImageSize = size(new_image);
            end
          
            obj.LastImageSize = obj.OriginalImageSize;
            obj.LastDataType = class(obj.RawImage);

            addlistener(obj, 'ImageType', 'PostSet', @obj.ImagePropertyChangedCallback);
            addlistener(obj, 'Title', 'PostSet', @obj.ImagePropertyChangedCallback);
            addlistener(obj, 'GlobalOrigin', 'PostSet', @obj.ImagePropertyChangedCallback);            
        end
        
        function ChangeColorLabelMap(obj, new_colourmap)
            obj.ColorLabelMap = new_colourmap;
            obj.NotifyImageChanged;
        end
        
        function ChangeColorLabelParentChildMap(obj, new_parent_map, new_child_map)
            obj.ColourLabelParentMap = new_parent_map;
            obj.ColourLabelChildMap = new_child_map;
        end
        
        function raw_image = GetMappedRawImage(obj)
            if isempty(obj.ColorLabelMap)
                raw_image = obj.RawImage;
            else
                raw_image = obj.ColorLabelMap(obj.RawImage + 1);
            end
        end
        
        function orientation = Find2DOrientation(obj)
            image_size = obj.ImageSize;
            if image_size(3) == 1
                orientation = PTKImageOrientation.Axial;
            elseif image_size(2) == 1
                orientation = PTKImageOrientation.Sagittal;
            elseif image_size(1) == 1
                orientation = PTKImageOrientation.Coronal;
            else
                orientation = [];
            end
        end

        function raw_image_loaded = IsRawImageLoaded(obj)
            % Returns false if this image has a raw image that has not yet
            % beed loaded from disk

            raw_image_loaded = ~isempty(obj.RawImage) || isempty(obj.CachedRawImageFilename);
        end
        
        function LoadCachedRawImage(obj, raw_image)
            % For a disk-cached image header, this loads the raw data
            
            if ~obj.IsRawImageLoaded
                obj.RawImage = raw_image;
                
                % Clear cached values
                obj.CachedImageSize = [];
                obj.CachedDataType = [];
                obj.CachedRawImageFilename = [];
                obj.CachedRawImageCompression = [];

                obj.NotifyImageChangedCacheStillValid
            end
        end
        
        function header_file = CreateHeader(obj, raw_filename, compression)
            % Creates a cache header file template suitable for saving separately from pixel data
            
            header_file = obj.BlankCopy;
            
            % We cache these values in the image class so they can be retrieved
            % when loading the raw data
            header_file.CachedDataType = class(obj.RawImage);
            header_file.CachedImageSize = obj.ImageSize;
            header_file.CachedRawImageFilename = raw_filename;
            header_file.CachedRawImageCompression = compression;
        end
      
        
        function ChangeRawImage(obj, new_image, image_type)
            % Replaces the underlying raw image data. This function is used for
            % applying data which relates to the same original image; hence the
            % image size must be the same.
        
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
            obj.ColorLabelMap = [];
            obj.NotifyImageChanged;
        end
        
        function raw_image = GetRawImageForPlotting(obj)
            % Returns a raw image suitable for use with Matlab's plotting functions
            % such as isosurface. The k-direction is inverted since the orientation
            % for PTKImage is is opposite to that for Matlab's 3D axes
            
            raw_image = flipdim(obj.RawImage, 3);
        end
        
        function ChangeSubImage(obj, new_subimage)
            % This function changes part of the image, as defined by the origin of the subimage
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

        function masked_image = GetMask(obj, mask_index)
            % Returns an image mask, set to true for each voxel which equals the mask index
            if nargin < 2
                mask_index = 1;
            end
            masked_image = obj.BlankCopy;
            masked_image.ChangeRawImage(obj.RawImage == mask_index);
        end
        
        function masked_image = GetMaskedImage(obj, mask, mask_index)
            % Returns a copy of the image with every point outside of the mask set to zero
        
            if nargin < 3
                mask_index = 1;
            end
            masked_image = obj.BlankCopy;
            masked_image.ChangeRawImage(obj.RawImage.*cast(mask.RawImage == mask_index, class(obj.RawImage)));
        end
        
        function ChangeSubImageWithMask(obj, new_subimage, mask, mask_index)
            % Modifies a region of the image, using a mask to determine which voxels will be changed.
            if nargin < 4
                mask_index = [];
            end
            mask = mask.Copy;
            mask.ResizeToMatch(new_subimage);
            if ~mask.ImageExists
                mask.ChangeRawImage(true(mask.ImageSize));
            end

            if (length(mask.ImageSize) == 3) && (length(new_subimage.ImageSize) == 4)
                mask.ChangeRawImage(repmat(mask.RawImage, [1, 1, 1, new_subimage.ImageSize(4)]));
            end

            dst_offset = new_subimage.Origin - obj.Origin + [1 1 1];
            src_offset = obj.Origin - new_subimage.Origin + [1 1 1];
            
            dst_start_crop = max(1, dst_offset);
            dst_end_crop = min(obj.ImageSize(1:3), dst_offset + new_subimage.ImageSize(1:3) - 1);
            
            src_start_crop = max(1, src_offset);
            src_end_crop = min(new_subimage.ImageSize(1:3), src_offset + obj.ImageSize(1:3) - 1);
            
            existing_subimage_raw = obj.RawImage(...
                    dst_start_crop(1) : dst_end_crop(1), ...
                    dst_start_crop(2) : dst_end_crop(2), ...
                    dst_start_crop(3) : dst_end_crop(3), ...
                    : ...
                );
            
            mask_subimage_raw = mask.RawImage(...
                    src_start_crop(1) : src_end_crop(1), ...
                    src_start_crop(2) : src_end_crop(2), ...
                    src_start_crop(3) : src_end_crop(3), ...    
                    : ...
                );
            
            if ~isempty(mask_index)
                mask_subimage_raw = mask_subimage_raw == mask_index;
            else
                mask_subimage_raw = mask_subimage_raw > 0;
            end
            
            
            new_subimage_raw = new_subimage.RawImage(...
                    src_start_crop(1) : src_end_crop(1), ...
                    src_start_crop(2) : src_end_crop(2), ...
                    src_start_crop(3) : src_end_crop(3), ...    
                    : ...
                );
            
            existing_subimage_raw(mask_subimage_raw) = new_subimage_raw(mask_subimage_raw);

            obj.RawImage(...
                    dst_start_crop(1) : dst_end_crop(1), ...
                    dst_start_crop(2) : dst_end_crop(2), ...
                    dst_start_crop(3) : dst_end_crop(3), ...
                    : ...
                )  = existing_subimage_raw;
            
            obj.NotifyImageChanged;
        end
        
        function ResizeToMatch(obj, template_image)
            % Adjusts the image borders to match the specified template image
            
            obj.ResizeToMatchOriginAndSize(template_image.Origin, template_image.ImageSize)
        end
        
        function ResizeToMatchOriginAndSize(obj, new_origin, image_size)
            % Adjusts the image borders to match the specified origin and size
            
            src_offset = new_origin - obj.Origin + [1 1 1];
            dst_offset = obj.Origin - new_origin + [1 1 1];
            
            src_start_crop = max(1, src_offset);
            src_end_crop = min(obj.ImageSize(1:3), src_offset + image_size(1:3) - 1);
            
            dst_start_crop = max(1, dst_offset);
            dst_end_crop = min(image_size(1:3), dst_offset + obj.ImageSize(1:3) - 1);
            
            num_dims = min(length(image_size), length(obj.ImageSize));
            new_image_size = obj.ImageSize;
            new_image_size(1:num_dims) = image_size(1:num_dims);
            
            if obj.ImageExists
                if islogical(obj.RawImage)
                    new_rawimage = false(new_image_size);
                else
                    new_rawimage = zeros(new_image_size, class(obj.RawImage));
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
                obj.CheckForZeroImageSize;
            else
                obj.LastImageSize = new_image_size;
            end
            obj.Origin = new_origin;
            obj.NotifyImageChanged;
        end
        
        function copy = Copy(obj)
            % Makes a copy of this image, including its metadata and pixeldata
            copy = PTKImage(obj.RawImage, obj.ImageType, obj.VoxelSize);
            metaclass = ?PTKImage;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list);
                property = property_list{i};
                if (~property.Dependent) && (~property.Constant)
                    copy.(property.Name) = obj.(property.Name);
                end
            end
        end
        
        function copy = BlankCopy(obj)
            % Creates an copy of the image with all the metaheaders but no pixel data
            copy = PTKImage([], obj.ImageType, obj.VoxelSize);
            metaclass = ?PTKImage;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list);
                property = property_list{i};
                if (~property.Dependent) && (~property.Constant) && (~strcmp(property.Name, 'RawImage'))
                    copy.(property.Name) = obj.(property.Name);
                end
            end
        end
        
        function RescaleToMaxSize(obj, max_size)
            % Downscales the image so that it is below the specified value in all dimensions
            scale = [1 1 1];
            image_size = obj.ImageSize;
            original_image_size = image_size;
            for dim_index = 1 : 3
                while image_size(dim_index) > max_size
                    scale(dim_index) = scale(dim_index) + 1;
                    image_size = floor(original_image_size./scale);
                end
            end
            obj.DownsampleImage(scale);
        end
        
        function DownsampleImage(obj, scale)
            % Downscales the image by an integer amount, without any filtering.
            % Note this does not alter the OriginalImageSize property
            if length(scale) == 1
                scale = repmat(scale, 1, length(obj.Origin));
            end
            obj.VoxelSize = scale.*obj.VoxelSize;
            obj.Scale = scale.*obj.Scale;
            obj.RawImage = obj.RawImage(round(1:scale(1):end), round(1:scale(2):end), round(1:scale(3):end));
            obj.NotifyImageChanged;
            obj.Origin = floor(obj.Origin./scale);
        end
        
        function slice = GetSlice(obj, slice_number, dimension)
            % Returns a 2D slice from the image in the specified direction
           switch dimension
               case PTKImageOrientation.Coronal
                   slice = squeeze(obj.RawImage(slice_number, :, :));
               case PTKImageOrientation.Sagittal
                   slice = squeeze(obj.RawImage(:, slice_number, :));
               case PTKImageOrientation.Axial
                   slice = squeeze(obj.RawImage(:, :, slice_number));
               otherwise
                   error('Unsupported dimension');
           end
        end
        
        function slice = GetBlankSlice(obj, dimension)
            % Returns a blank slice from the image in the specified direction
            
            switch dimension
                case PTKImageOrientation.Coronal
                    slice = MimImageUtilities.Zeros([obj.ImageSize(2), obj.ImageSize(3)], obj.LastDataType);
                case PTKImageOrientation.Sagittal
                    slice = MimImageUtilities.Zeros([obj.ImageSize(1), obj.ImageSize(3)], obj.LastDataType);
                case PTKImageOrientation.Axial
                    slice = MimImageUtilities.Zeros([obj.ImageSize(1), obj.ImageSize(2)], obj.LastDataType);
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
        
        function limits = get.Limits(obj)
            if obj.CachedDataIsValid
                limits = obj.CachedLimits;
            else
                limits = [min(obj.RawImage(:)), max(obj.RawImage(:))];
                obj.CachedLimits = limits;
                obj.CachedDataIsValid = true;
            end
        end

        function [value, units] = GetRescaledValue(~, ~)
            value = [];
            units = [];
        end

        function units_rescaled = GrayscaleToRescaled(~, units_greyscale)
            units_rescaled = units_greyscale;
        end

        function units_greyscale = RescaledToGrayscale(~, units_rescaled)
            units_greyscale = units_rescaled;
        end

        function point_is_in_image = IsPointInImage(obj, global_coords)
            % Returns true if the point specified in global coordinates lies within the image
            local_coords = obj.GlobalToLocalCoordinates(global_coords);
            image_size = obj.ImageSize;
            i_in_image = (local_coords(1) > 0) && (local_coords(1) <= image_size(1));
            j_in_image = (local_coords(2) > 0) && (local_coords(2) <= image_size(2));
            k_in_image = (local_coords(3) > 0) && (local_coords(3) <= image_size(3));
            point_is_in_image = i_in_image && j_in_image && k_in_image;
        end

        function value = GetVoxel(obj, global_coords)
            % Gets the value of the voxel specified by global image coordinates
            local_coords = obj.GlobalToLocalCoordinates(global_coords);
            value = obj.RawImage(local_coords(1), local_coords(2), local_coords(3));
        end
        
        function SetVoxelToThis(obj, global_coords, value)
            % Changes the value of the voxel specified by global image coordinates
            local_coords = obj.GlobalToLocalCoordinates(global_coords);
            for index = 1 : size(local_coords, 1)
                obj.RawImage(local_coords(index, 1), local_coords(index, 2), local_coords(index, 3)) = value;
            end
            obj.NotifyImageChanged;
        end

        function SetIndexedVoxelsToThis(obj, global_indices, value)
            % Changes the value of the voxel specified by an index value
            local_indices = obj.GlobalToLocalIndices(global_indices);
            obj.RawImage(local_indices) = value;
            obj.NotifyImageChanged;
        end

        function Clear(obj)
            % Sets all image values to zero
            obj.RawImage(:) = 0;
            obj.NotifyImageChanged;
        end

        function Reset(obj)
            % Deletes the image
            obj.RawImage = [];
            obj.NotifyImageChanged;
        end

        function Flatten(obj, direction)
            % Creates an image projection in the specified direction
            flat = max(obj.RawImage, [], direction);
            number_of_repeats = size(obj.RawImage, direction);
            switch direction
                case PTKImageOrientation.Coronal
                    obj.RawImage = repmat(flat, [number_of_repeats 1 1]);
                case PTKImageOrientation.Sagittal
                    obj.RawImage = repmat(flat, [1 number_of_repeats 1]);
                case PTKImageOrientation.Axial
                    obj.RawImage = repmat(flat, [1 1 number_of_repeats]);
            end
            obj.NotifyImageChanged;
        end
        
        function ReplaceImageSlice(obj, new_slice, slice_index, direction)
            % Modifies the specified 2D slice of the image
            switch direction
                case PTKImageOrientation.Coronal
                    obj.RawImage(slice_index, :, :) = new_slice;
                case PTKImageOrientation.Sagittal
                    obj.RawImage(:, slice_index, :) = new_slice;
                case PTKImageOrientation.Axial
                    obj.RawImage(:, :, slice_index) = new_slice;
            end
            obj.NotifyImageChanged;
        end
        
        function CropToFit(obj)
            % Removes boundary zeros; i.e. strips away planes of zeros from the edges of the image
            if obj.ImageExists
                bounds = obj.GetBounds;
                if isempty(bounds)
                    obj.RawImage = [];
                    obj.CheckForZeroImageSize;
                    obj.NotifyImageChanged;
                else
                    % Create new image
                    obj.RawImage = obj.RawImage(bounds(1):bounds(2), bounds(3):bounds(4), bounds(5):bounds(6));
                    obj.Origin = obj.Origin + [bounds(1) - 1, bounds(3) - 1, bounds(5) - 1];
                    obj.NotifyImageChanged;
                end
            end
        end
        
        function CropToFitWithBorder(obj, border_size)
            % Removes boundary zeros, ensuring a border of zero voxels remains
            
            if obj.ImageExists
                image_size = obj.ImageSize;
                bounds = obj.GetBounds;
                if isempty(bounds)
                    obj.RawImage = [];
                    obj.NotifyImageChanged;
                    obj.CheckForZeroImageSize;
                    return;
                end
                
                bounds(1) = max(1, bounds(1) - border_size);
                bounds(3) = max(1, bounds(3) - border_size);
                bounds(5) = max(1, bounds(5) - border_size);
                
                bounds(2) = min(image_size(1), bounds(2) + border_size);
                bounds(4) = min(image_size(2), bounds(4) + border_size);
                bounds(6) = min(image_size(3), bounds(6) + border_size);
                
                % Create new image
                obj.RawImage = obj.RawImage(bounds(1):bounds(2), bounds(3):bounds(4), bounds(5):bounds(6));
                
                obj.Origin = obj.Origin + [bounds(1) - 1, bounds(3) - 1, bounds(5) - 1];
                obj.NotifyImageChanged;
            end
        end
        
        function bounds = GetBounds(obj)
            % Returns the bounding cordinates of a binary image
            bounds = [];
            i_min = find(any(any(obj.RawImage, 2), 3), 1, 'first');
            if isempty(i_min)
                return; 
            end
            i_max = find(any(any(obj.RawImage, 2), 3), 1, 'last' );
            
            j_min = find(any(any(obj.RawImage, 1), 3), 1, 'first');
            if isempty(j_min)
                return; 
            end
            j_max = find(any(any(obj.RawImage, 1), 3), 1, 'last' );
            
            k_min = find(any(any(obj.RawImage, 1), 2), 1, 'first');
            if isempty(k_min)
                return; 
            end
            k_max = find(any(any(obj.RawImage, 1), 2), 1, 'last' );
            
            bounds = [i_min, i_max, j_min, j_max, k_min, k_max];
        end
        
        function Crop(obj, start_crop, end_crop)
            % Strips away a border around the image, returning the region specified by start_crop and end_crop
            if obj.ImageExists
                obj.RawImage = obj.RawImage(start_crop(1):end_crop(1), start_crop(2):end_crop(2), start_crop(3):end_crop(3));
                obj.CheckForZeroImageSize;
            else
                obj.LastImageSize = [1 + end_crop(1) - start_crop(1), 1 + end_crop(2) - start_crop(2), 1 + end_crop(3) - start_crop(3)];
            end
            obj.Origin = obj.Origin + [start_crop(1) - 1, start_crop(2) - 1, start_crop(3) - 1];
            obj.NotifyImageChanged;
        end
        
        function AddBorder(obj, border_size)
            % Adds a blank border of border_size voxels to the image in all dimensions
            if numel(border_size) == 3
                added_size = border_size;
            else
                added_size = [border_size border_size border_size];
            end
            if ~obj.ImageExists
                obj.LastImageSize = obj.LastImageSize + 2*added_size;
            else
                class_name = class(obj.RawImage);
                if islogical(obj.RawImage)
                    new_image = false(obj.ImageSize + 2*added_size);
                else
                    new_image = zeros(obj.ImageSize + 2*added_size, class_name);
                end
                
                new_image(1+added_size(1):end-added_size(1), 1+added_size(2):end-added_size(2), 1+added_size(3):end-added_size(3)) = obj.RawImage;
                obj.RawImage = new_image;
                obj.CheckForZeroImageSize;
            end
            obj.Origin = obj.Origin - added_size;
            obj.NotifyImageChanged;
        end
        
        function RemoveBorder(obj, border_size)
            % Removes a border of border_size voxels from the image in all dimensions
            added_size = [border_size border_size border_size];
            if ~obj.ImageExists
                obj.LastImageSize = obj.LastImageSize - 2*added_size;
            else
                obj.RawImage = obj.RawImage(1+border_size : end-border_size, 1+border_size : end-border_size, 1+border_size : end-border_size);
            end
            obj.Origin = obj.Origin + added_size;
            obj.NotifyImageChanged;
        end
        
        function ResampleBinary(obj, new_voxel_size_mm)
            % Similar to resample, but uses a linear interpolation followed by thresholding to ensure a smoother binary mask
            is_logical = islogical(obj.RawImage);
            obj.ChangeRawImage(single(obj.RawImage));
            obj.ResampleWithAffineTransformation(new_voxel_size_mm, '*linear', []);
            if is_logical
                obj.ChangeRawImage(obj.RawImage > 0.5);
            else
                obj.ChangeRawImage(uint8(obj.RawImage > 0.5));
            end
        end
        
        function Resample(obj, new_voxel_size_mm, interpolation_function)
            % Resamples the image to a new voxel size, using the specified interpolation method.
            % The resampling is based on the origin of the original image, so that the position of the new voxels is consistent
            % between images. The resulting image is cropped to the region
            % containing all of the previous image
            obj.ResampleWithAffineTransformation(new_voxel_size_mm, interpolation_function, []);
        end
        
        function ResampleWithAffineTransformation(obj, new_voxel_size_mm, interpolation_function, affine_matrix)
            % Find the bounding coordinates in mm of the original image
            min_old_coords_mm = (obj.Origin - [1, 1, 1]).*obj.VoxelSize;
            max_old_coords_mm = (obj.Origin + obj.ImageSize - [1, 1, 1]).*obj.VoxelSize;
            
            % Get 1-indexed bounding voxel coordinates of the new image
            min_new_coords = [1, 1, 1] + floor(min_old_coords_mm./new_voxel_size_mm);
            max_new_coords = ceil(max_old_coords_mm./new_voxel_size_mm);

            % Find the coordinates of the centre of each of the new voxels
            new_i = min_new_coords(1) : max_new_coords(1);
            new_j = min_new_coords(2) : max_new_coords(2);
            new_k = min_new_coords(3) : max_new_coords(3);
            new_i_mm = (new_i' - 0.5)*new_voxel_size_mm(1);
            new_j_mm = (new_j' - 0.5)*new_voxel_size_mm(2);
            new_k_mm = (new_k' - 0.5)*new_voxel_size_mm(3);
            
            % We must add a border around the image before we interpolate. This
            % is because our coordinates refer to the voxel centres. However,
            % interpolation uses these coordinates to determine minimum and
            % maximum values for the coordinates of the interpolated voxels;
            % outside of these minima and maxima the output will be set to the
            % extrapolation value, even if that voxel lies partly or wholly
            % within the original image. To fix this we need to extend the image
            % domain by one voxel in each direction so that the interpolation
            % can extend to all voxels which are mostly enclosed by the original
            % image. The AddBorder method neatly does this, correctly adjusting
            % the origin so the GetGlobalCoordinatesMm method will work.
            % Note this MUST de done AFTER the new coordinates have been
            % computed, so that they relate to the image before the border is
            % added.
            obj.AddBorder(1);
            
            if isempty(obj.RawImage)
                obj.LastImageSize = [size(new_i, 2), size(new_j, 2), size(new_k, 2)];
            else
                % Fetch coordinates for each voxel within the existing image. Note
                % this MUST be done AFTER the AddBorder call.
                [old_i_mm, old_j_mm, old_k_mm] = obj.GetGlobalCoordinatesMm;
                
                [old_i_grid, old_j_grid, old_k_grid] = ndgrid(old_i_mm, old_j_mm, old_k_mm);
                [new_i_grid, new_j_grid, new_k_grid] = ndgrid(new_i_mm, new_j_mm, new_k_mm);
                
                if ~isempty(affine_matrix)
                    [new_i_grid, new_j_grid, new_k_grid] = MimImageCoordinateUtilities.TransformCoordsAffine(new_i_grid, new_j_grid, new_k_grid, affine_matrix);
                end
                
                % Find the nearest value for each point in the new grid
                obj.RawImage = interpn(old_i_grid, old_j_grid, old_k_grid, obj.RawImage, new_i_grid, new_j_grid, new_k_grid, interpolation_function, 0);
                obj.CheckForZeroImageSize;
            end
            
            obj.Origin = min_new_coords;
            obj.OriginalImageSize = ceil((obj.OriginalImageSize.*obj.VoxelSize)./new_voxel_size_mm);
            obj.VoxelSize = new_voxel_size_mm;
            obj.Scale = [1, 1, 1];
            obj.NotifyImageChanged;            
        end
        
        function Morph(obj, morph_function_handle, size_mm)
            % Performs a Matlab morphological operation using a spherical element of the specified size in mm, adjusting for the voxel size
            ball_element = obj.CreateBallStructuralElement(size_mm);
            obj.RawImage = uint8(morph_function_handle(obj.RawImage, ball_element));
            obj.NotifyImageChanged;
        end

        function BinaryMorph(obj, morph_function_handle, size_mm)
            % Performs a Matlab binary morphological operation using a spherical element of the specified size in mm, adjusting for the voxel size
            ball_element = obj.CreateBallStructuralElement(size_mm);
            obj.RawImage = obj.RawImage > 0;
            obj.RawImage = logical(morph_function_handle(obj.RawImage, ball_element));
            obj.NotifyImageChanged;
        end
        
        function MorphWithBorder(obj, morph_function_handle, size_mm)
            % Performs a Matlab morphological operation as with Morph(), but first adds an additional boder to the image
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
        
        function GeneratePreview(obj, preview_size, flatten_before_preview)
            % Creates a 2D thumbnail preview image and stores it in the Preview property
            [preview_image_slice, preview_scale] = MimImageUtilities.GeneratePreviewImage(obj, preview_size, flatten_before_preview);
            obj.Preview = obj.BlankCopy;
            obj.Preview.RawImage = preview_image_slice;
            obj.Preview.Scale = [preview_scale, preview_scale];
            obj.Preview.GlobalLimits = obj.Limits;
        end
        
        function is_equal = eq(obj, other)
            metaclass = ?PTKImage;
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
            global_coords = repmat(obj.Origin - [1, 1, 1], size(coords,1), 1) + coords;
        end
        
        function local_coords = GlobalToLocalCoordinates(obj, global_coords)
            local_coords = global_coords + repmat([1, 1, 1] - obj.Origin, size(global_coords, 1), 1);
        end
        
        function global_indices = LocalToGlobalIndices(obj, local_indices)
            global_indices = MimImageCoordinateUtilities.OffsetIndices(local_indices, obj.Origin - [1, 1, 1], obj.ImageSize, obj.OriginalImageSize);
        end
        
        function local_indices = GlobalToLocalIndices(obj, global_indices)
            local_indices = MimImageCoordinateUtilities.OffsetIndices(global_indices, [1, 1, 1] - obj.Origin, obj.OriginalImageSize, obj.ImageSize);
        end
        
        function [ic, jc, kc] = GlobalIndicesToCoordinatesMm(obj, global_indices)
            % Given a set of global indices, compute the coordinates of each in mm
            [ic, jc, kc] = obj.GlobalIndicesToGlobalCoordinates(global_indices);
            [ic, jc, kc] = obj.GlobalCoordinatesToCoordinatesMm([ic, jc, kc]);
        end
        
        function ptk_coordinates = GlobalIndicesToPTKCoordinates(obj, global_indices)
            % Given a set of global indices, compute the coordinates of each in mm
            [ic, jc, kc] = obj.GlobalIndicesToCoordinatesMm(global_indices);
            [ic, jc, kc] = MimImageCoordinateUtilities.CoordinatesMmToPTKCoordinates(ic, jc, kc);
            ptk_coordinates = [ic, jc, kc];
        end
        
        function [ic, jc, kc] = GlobalCoordinatesToCoordinatesMm(obj, global_coordinates)
            % Given a set of global indices, compute the coordinates of each in mm
            ic = (global_coordinates(:, 1) - 0.5)*obj.VoxelSize(1);
            jc = (global_coordinates(:, 2) - 0.5)*obj.VoxelSize(2);
            kc = (global_coordinates(:, 3) - 0.5)*obj.VoxelSize(3);
        end
        
        function [ic, jc, kc] = GlobalIndicesToGlobalCoordinates(obj, global_indices)
            [ic, jc, kc] = ind2sub(obj.OriginalImageSize, global_indices);
        end
        
        function global_coordinates = CoordinatesMmToGlobalCoordinates(obj, global_coordinates_mm)
            % Given a set of coordinates in mm, compute the global coordinates of each
            if isempty(global_coordinates_mm)
                global_coordinates = [];
            else
                global_coordinates = repmat([1, 1, 1], size(global_coordinates_mm, 1), 1) + floor(global_coordinates_mm./repmat(obj.VoxelSize, size(global_coordinates_mm, 1), 1));
            end
            
        end
        
        function global_coordinates = CoordinatesMmToGlobalCoordinatesUnrounded(obj, global_coordinates_mm)
            % Given a set of coordinates in mm, compute the global coordinates of each
            if isempty(global_coordinates_mm)
                global_coordinates = [];
            else
                global_coordinates = repmat([1, 1, 1], size(global_coordinates_mm, 1), 1) + global_coordinates_mm./repmat(obj.VoxelSize, size(global_coordinates_mm, 1), 1);
            end 
        end
        
        function global_indices = GlobalCoordinatesToGlobalIndices(obj, coords)
            global_indices = MimImageCoordinateUtilities.FastSub2ind(obj.OriginalImageSize, coords(:, 1), coords(:, 2), coords(:, 3));
        end
        
        function [ic, jc, kc] = GetGlobalCoordinatesMm(obj)
            % Compute the coordinates of all points in the image, in global coordinates in mm
            ic = 1 : obj.ImageSize(1);
            ic = (ic' + obj.Origin(1) - 1.5)*obj.VoxelSize(1);
            jc = 1 : obj.ImageSize(2);
            jc = (jc' + obj.Origin(2) - 1.5)*obj.VoxelSize(2);
            kc = 1 : obj.ImageSize(3);
            kc = (kc' + obj.Origin(3) - 1.5)*obj.VoxelSize(3);
        end

        function [ic, jc, kc] = GetCentredGlobalCoordinatesMm(obj)
            % Returns the coordinates of all points in the image in global coordinates in mm, with the origin at the centre of the original image
            [ic, jc, kc] = obj.GetGlobalCoordinatesMm;
            [ic, jc, kc] = obj.GlobalCoordinatesMmToCentredGlobalCoordinatesMm(ic, jc, kc);
        end
        
        function [ic, jc, kc] = GetCornerGlobalCoordinatesMm(obj)
            % Returns the coordinates of all points in the image in global coordinates in mm, with the origin at the centre of the original image
            [ic, jc, kc] = obj.GetGlobalCoordinatesMm;
            [ic, jc, kc] = obj.GlobalCoordinatesMmToCornerCoordinates(ic, jc, kc);
        end
        
        function [ic, jc, kc] = GetPTKCoordinates(obj)
            % Returns the coordinates of all points in the image in global coordinates in mm, using PTK coordinates
            [ic, jc, kc] = obj.GetGlobalCoordinatesMm;
            [ic, jc, kc] = MimImageCoordinateUtilities.CoordinatesMmToPTKCoordinates(ic, jc, kc);
        end
        
        function [xc, yc, zc] = GetDicomCoordinates(obj)
            % Returns the coordinates of all points in the image in Dicom coordinates in mm
            [ic, jc, kc] = GetPTKCoordinates(obj);
            [xc, yc, zc] = MimImageCoordinateUtilities.PTKToDicomCoordinatesCoordwise(ic, jc, kc, obj);
        end
        
        function [xc, yc, zc] = GlobalCoordinatesMmToCornerCoordinates(obj, ic, jc, kc)
            voxel_size = obj.VoxelSize;
            
            % Adjust to coordinates at centre of first voxel
            offset = -voxel_size/2;
            offset = [offset(2), offset(1), -offset(3)];
            
            % Shift the global origin to the first slice of the image
            global_origin = [0, 0, 0];
            
            % Adjust to Dicom origin
            offset = offset + global_origin;
            
            xc = jc + offset(1);
            yc = ic + offset(2);
            zc = -kc + offset(3);
        end

        function [ic, jc, kc] = GlobalCoordinatesMmToCentredGlobalCoordinatesMm(obj, ic, jc, kc)
            % Translates global coordinates in mm so that the origin is in the centre of the image
            original_voxel_size = obj.VoxelSize./obj.Scale;
            offset = obj.OriginalImageSize.*original_voxel_size/2;
            ic = ic - offset(1);
            jc = jc - offset(2);
            kc = kc - offset(3);
        end
        
        function grid_spacing_mm = ComputeResamplingGridSpacing(obj, approx_number_points)
            % Computes the isotropic grid spacing required to resample this mask so as to achieve approximately the number of specified points in the mask
            number_of_voxels = sum(obj.RawImage(:) > 0);
            parallelepiped_volume = prod(obj.VoxelSize);
            grid_spacing_mm = nthroot(parallelepiped_volume*(number_of_voxels/approx_number_points), 3);
        end
        
        function InterpolationToMatch(obj, template)
            % Interpolates the image to the coordinates in the template image
            
            [i_o, j_o, k_o] = obj.GetGlobalCoordinatesMm;
            [i_o, j_o, k_o] = ndgrid(i_o, j_o, k_o);
            
            [i_r, j_r, k_r] = template.GetGlobalCoordinatesMm;
            [i_r, j_r, k_r] = ndgrid(i_r, j_r, k_r);
            
            obj.RawImage = interpn(i_o, j_o, k_o, single(obj.RawImage), ...
                i_r, j_r, k_r, '*linear', 0);
            obj.Origin = template.Origin;
            obj.VoxelSize = template.VoxelSize;
            obj.NotifyImageChanged;
        end
        
        function volume_mm3 = Volume(obj)
            % Computes the volume of the segmentation image in mm^3
            voxel_volume_mm3 = prod(obj.VoxelSize);
            volume_mm3 = voxel_volume_mm3*sum(obj.RawImage(:) > 0);
        end
        
        function ChangeColourIndex(obj, old_index, new_index, reporting)
            if ~isinteger(obj.RawImage)
                reporting.Error('PTKImage:ChangeColourIndexRequiresInteger', 'ChangeColourIndex() can only be called on images with integer data types');
            end
            obj.RawImage(obj.RawImage == old_index) = new_index;
        end
        
        function offset_in_mm = GetCornerOffset(obj)
            % Computes the offset from PTK to unshifted Dicom coordinates
            voxel_size = obj.VoxelSize;
            
            % Adjust to coordinates at centre of first voxel
            offset = -voxel_size/2;
            offset_in_mm = [offset(1), offset(2), -offset(3)];
        end

        function offset_in_mm = GetDicomOffset(obj)
            % Computes the offset from PTK to unshifted Dicom coordinates

            global_origin = obj.GlobalOrigin;
            global_origin = global_origin([2, 1, 3]);
            voxel_size = obj.VoxelSize;
            original_image_size = obj.OriginalImageSize;
            
            % Adjust to coordinates at centre of first voxel
            offset = -voxel_size/2;
            offset = [offset(1), offset(2), -offset(3)];
            
            % Shift the global origin to the first slice of the image
            global_origin(3) = global_origin(3) + (original_image_size(3) - 1)*voxel_size(3);
            
            % Adjust to Dicom origin
            offset_in_mm = offset + global_origin;
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
            ball_element = CoreImageUtilities.CreateBallStructuralElement(obj.VoxelSize, size_mm);
        end
        
        % Guesses which type of image rendering would be best. 
        function image_type = GuessImageType(obj)
            if isempty(obj.RawImage)
                image_type = PTKImageType.Colormap;
                return
            end
            if islogical(obj.RawImage)
                % For binary images, opt for a simple colormap
                image_type = PTKImageType.Colormap;
            else
                % If the image data is noninteger then assume greyscale
                if ~CoreMathUtilities.IsMatrixInteger(obj.RawImage)
                    image_type = PTKImageType.Grayscale;
                else
                    % Otherwise choose colormap if the range of values is
                    % restricted
                    if (min(obj.RawImage(:))) >= 0 && (max(obj.RawImage(:)) <= 7)
                        image_type = PTKImageType.Colormap;
                    else
                        image_type = PTKImageType.Grayscale;
                    end
                end
            end
        end
        
        % Settings have changed
        function ImagePropertyChangedCallback(obj, ~, ~, ~)
            obj.NotifyImageChanged;
        end
        
        % If a cropping operation removes the entire image, we need to set the
        % LastImageSize to zero, otherwise it will be assumed the image is template 
        function CheckForZeroImageSize(obj)
            if isempty(obj.RawImage)
                obj.LastImageSize = [0, 0, 0];
            end
        end
    end
        
end