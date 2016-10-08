classdef PTKImageFromVolume < GemImage
    % PTKImageFromVolume. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKImageFromVolume holds a volume, and a 2D image object
    %     which shows one slice from the image volume
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = protected)
        DisplayParameters
        ImageParameters
        ImageSource
        ReferenceImageSource % Used for fusing two images to adjust the positioning of an image
    end
    
    methods
        function obj = PTKImageFromVolume(parent, image_source, image_parameters, display_parameters, reference_image_source)
            obj = obj@GemImage(parent);
            obj.ImageSource = image_source;
            obj.ImageParameters = image_parameters;
            obj.DisplayParameters = display_parameters;
            obj.ReferenceImageSource = reference_image_source;
        end

        function DrawImage(obj)
            obj.DrawImageSlice;
        end

        function DrawImageSlice(obj)
            reference_image = obj.ReferenceImageSource.Image;
            window = obj.DisplayParameters.Window;
            level = obj.DisplayParameters.Level;
            opacity = obj.DisplayParameters.Opacity*obj.DisplayParameters.ShowImage;
            black_is_transparent = obj.DisplayParameters.BlackIsTransparent;
            opaque_colour = obj.DisplayParameters.OpaqueColour;
            image_object = obj.ImageSource.Image;
            orientation = obj.ImageParameters.Orientation;
            slice_number = obj.ImageParameters.SliceNumber(orientation);
            if ~isempty(image_object)
                if image_object.ImageExists
                    image_slice = PTKImageFromVolume.GetImageSlice(reference_image, image_object, slice_number, orientation);
                    image_type = image_object.ImageType;
                    
                    if (image_type == PTKImageType.Scaled)
                        limits = image_object.Limits;
                    elseif (image_type == PTKImageType.Colormap)
                        
                        % For unsigned types, we don't need the limits (see GetImage() below)
                        if isa(image_slice, 'uint8') || isa(image_slice, 'uint16')
                            limits = [];
                        else
                            limits = image_object.Limits;
                        end
                    else
                        limits = [];
                    end
                    
                    level_grayscale = image_object.RescaledToGrayscale(level);
                    window_grayscale = window;
                    if isa(image_object, 'PTKDicomImage')
                        if image_object.IsCT && ~isempty(image_object.RescaleSlope)
                            window_grayscale = window_grayscale/image_object.RescaleSlope;
                        end
                    end
                    
                    [rgb_slice, alpha_slice] = PTKImageFromVolume.GetImage(image_slice, limits, image_type, window_grayscale, level_grayscale, black_is_transparent, image_object.ColorLabelMap);
                    alpha_slice = double(alpha_slice)*opacity/100;
                    
                    % Special code to highlight one colour
                    if ~isempty(opaque_colour)
                        alpha_slice(image_slice == opaque_colour) = 1;
                    end
                    
                    obj.SetImageData(rgb_slice, alpha_slice);
                else
                    obj.ClearImageData;
                end
            end
        end
        
        function SetRangeWithPositionAdjustment(obj, x_range, y_range)
            [dim_x_index, dim_y_index, ~] = GemUtilities.GetXYDimensionIndex(obj.ImageParameters.Orientation);
            
            overlay_offset_voxels = PTKImageCoordinateUtilities.GetOriginOffsetVoxels(obj.ReferenceImageSource.Image, obj.ImageSource.Image);
            overlay_offset_x_voxels = overlay_offset_voxels(dim_x_index);
            overlay_offset_y_voxels = overlay_offset_voxels(dim_y_index);
            obj.SetRange(x_range - overlay_offset_x_voxels, y_range - overlay_offset_y_voxels);
        end
    end
    
    methods (Access = private, Static)
        
        function [rgb_slice, alpha_slice] = GetImage(image_slice, limits, image_type, window, level, black_is_transparent, map)
            switch image_type
                case PTKImageType.Grayscale
                    rescaled_image_slice = PTKImageFromVolume.RescaleImage(image_slice, window, level);
                    [rgb_slice, alpha_slice] = PTKImageFromVolume.GetBWImage(rescaled_image_slice);
                case PTKImageType.Colormap
                    
                    % An empty limits indicates the value should never be below zero. This saves
                    % having to fetch the actual limits in the calling function, which is slow if
                    % done interactively
                    if ~isempty(limits) && limits(1) < 0
                        image_slice = image_slice - limits(1);
                    end
                    [rgb_slice, alpha_slice] = PTKImageFromVolume.GetLabeledImage(image_slice, map, black_is_transparent);
                case PTKImageType.Scaled
                    [rgb_slice, alpha_slice] = PTKImageFromVolume.GetColourMap(image_slice, limits, black_is_transparent);
            end
            
        end
        
        function image_slice = GetImageSlice(background_image, image_object, slice_number, orientation)
            offset_voxels = PTKImageCoordinateUtilities.GetOriginOffsetVoxels(background_image, image_object);
            
            slice_number = slice_number - round(offset_voxels(orientation));
            if (slice_number < 1) || (slice_number > image_object.ImageSize(orientation))
                image_slice = image_object.GetBlankSlice(orientation);
            else
                image_slice = image_object.GetSlice(slice_number, orientation);
            end
            if (orientation ~= GemImageOrientation.XY)
                image_slice = image_slice';
            end
        end
        
        
        function rescaled_image = RescaleImage(image, window, level)
            min_value = double(level) - double(window)/2;
            max_value = double(level) + double(window)/2;
            scale_factor = 255/max(1, (max_value - min_value));
            rescaled_image = uint8(min(((image - min_value)*scale_factor), 255));
        end
        
        function [rgb_image, alpha] = GetBWImage(image)
            rgb_image = (cat(3, image, image, image));
            alpha = ones(size(image));
        end
        
        function [rgb_image, alpha] = GetLabeledImage(image, map, black_is_transparent)
            if isempty(map)
                if isa(image, 'double') || isa(image, 'single')
                    rgb_image = CoreLabel2Rgb(round(image));
                else
                    rgb_image = CoreLabel2Rgb(image);
                end
            else
                if isa(image, 'double') || isa(image, 'single')
                    rgb_image = CoreLabel2Rgb(map(round(image + 1)));
                else
                    mapped_image = uint8(1 + mod(image, numel(map)));
                    rgb_image = CoreLabel2Rgb(map(mapped_image));
                end  
            end
            if black_is_transparent
                alpha = int8(image ~= 0);
            else
                alpha = ones(size(image));
            end            
        end
        
        function [rgb_image, alpha] = GetColourMap(image, image_limits, black_is_transparent)
            image_limits(1) = min(-1, image_limits(1));
            image_limits(2) = max(1, image_limits(2));
            positive_mask = image >= 0;
            rgb_image = zeros([size(image), 3], 'uint8');
            positive_image = abs(double(image))/abs(double(image_limits(2)));
            negative_image = abs(double(image))/abs(double(image_limits(1)));
            rgb_image(:, :, 1) = uint8(positive_mask).*(uint8(255*positive_image));
            rgb_image(:, :, 3) = uint8(~positive_mask).*(uint8(255*negative_image));
            
            if black_is_transparent
                alpha = double(positive_mask).*positive_image + single(~positive_mask).*negative_image;
                rgb_image(:, :, 1) = 255*uint8(positive_mask);
                rgb_image(:, :, 3) = 255*uint8(~positive_mask);
            else
                alpha = ones(size(image));
            end
        end
        
    end
    
end