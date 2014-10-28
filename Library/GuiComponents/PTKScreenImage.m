classdef PTKScreenImage < PTKPositionlessUserInterfaceObject
    % PTKScreenImage. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKScreenImage holds an image object
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = protected)
        XData
        YData
    end
    
    properties (Access = private)
        CData
        AlphaData
    end
    
    methods
        
        function obj = PTKScreenImage(parent)
            obj = obj@PTKPositionlessUserInterfaceObject(parent);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            obj.GraphicalComponentHandle = image([], 'Parent', obj.Parent.GetContainerHandle(reporting));
            
            if ~isempty(obj.XData)
                set(obj.GraphicalComponentHandle, 'XData', obj.XData, 'YData', obj.YData);
            end
            if ~isempty(obj.CData)
                alpha_slice = obj.AlphaData;
                if isempty(alpha_slice)
                    alpha_slice = 1;
                end
                set(obj.GraphicalComponentHandle, 'CData', obj.CData, 'AlphaData', alpha_slice, 'AlphaDataMapping', 'none');
            end
        end
        
        function SetRange(obj, x_range, y_range)
            obj.XData = x_range;
            obj.YData = y_range;
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                set(obj.GraphicalComponentHandle, 'XData', x_range, 'YData', y_range);
            end
        end
        
        function SetImageData(obj, rgb_slice, alpha_slice)
            obj.CData = rgb_slice;
            obj.AlphaData = alpha_slice;
            
            if isempty(alpha_slice)
                alpha_slice = 1;
            end
            
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                set(obj.GraphicalComponentHandle, 'CData', rgb_slice, 'AlphaData', alpha_slice, 'AlphaDataMapping', 'none');
            end
        end
        
        function ClearImageData(obj)
            obj.CData = [];
            obj.AlphaData = [];
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                % You can't set the AlphaData property to an empty matrix -
                % it must be set to 1 otherwise you get weird rendering
                % artefacts
                set(obj.GraphicalComponentHandle, 'CData', [], 'AlphaData', 1);
            end
        end
        
        function DrawImageSlice(obj, image_object, background_image, opacity, black_is_transparent, window, level, opaque_colour, slice_number, orientation)
            if ~isempty(image_object)
                if image_object.ImageExists
                    image_slice = obj.GetImageSlice(background_image, image_object, slice_number, orientation);
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
                    
                    [rgb_slice, alpha_slice] = PTKScreenImage.GetImage(image_slice, limits, image_type, window_grayscale, level_grayscale, black_is_transparent, image_object.ColorLabelMap);
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
    end
    
    methods (Access = private, Static)
        
        function [rgb_slice, alpha_slice] = GetImage(image_slice, limits, image_type, window, level, black_is_transparent, map)
            switch image_type
                case PTKImageType.Grayscale
                    rescaled_image_slice = PTKScreenImage.RescaleImage(image_slice, window, level);
                    [rgb_slice, alpha_slice] = PTKScreenImage.GetBWImage(rescaled_image_slice);
                case PTKImageType.Colormap
                    
                    % An empty limits indicates the value should never be below zero. This saves
                    % having to fetch the actual limits in the calling function, which is slow if
                    % done interactively
                    if ~isempty(limits) && limits(1) < 0
                        image_slice = image_slice - limits(1);
                    end
                    [rgb_slice, alpha_slice] = PTKScreenImage.GetLabeledImage(image_slice, map);
                case PTKImageType.Scaled
                    [rgb_slice, alpha_slice] = PTKScreenImage.GetColourMap(image_slice, limits, black_is_transparent);
            end
            
        end
        
        function [rgb_image, alpha] = GetBWImage(image)
            rgb_image = (cat(3, image, image, image));
            alpha = ones(size(image));
        end
        
        function [rgb_image, alpha] = GetLabeledImage(image, map)
            if isempty(map)
                if isa(image, 'double') || isa(image, 'single')
                    rgb_image = label2rgb(round(image), 'lines');
                else
                    rgb_image = label2rgb(image, 'lines');
                end
            else
                if isa(image, 'double') || isa(image, 'single')
                    rgb_image = label2rgb(map(round(image + 1)), 'lines');
                else
                    rgb_image = label2rgb(map(image + 1), 'lines');
                end
            end
            alpha = int8(image ~= 0);
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
        
        function rescaled_image = RescaleImage(image, window, level)
            min_value = double(level) - double(window)/2;
            max_value = double(level) + double(window)/2;
            scale_factor = 255/max(1, (max_value - min_value));
            rescaled_image = uint8(min(((image - min_value)*scale_factor), 255));
        end
        
        function image_slice = GetImageSlice(background_image, image_object, slice_number, orientation)
            offset_voxels = PTKImageCoordinateUtilities.GetOriginOffsetVoxels(background_image, image_object);
            
            slice_number = slice_number - round(offset_voxels(orientation));
            if (slice_number < 1) || (slice_number > image_object.ImageSize(orientation))
                image_slice = image_object.GetBlankSlice(orientation);
            else
                image_slice = image_object.GetSlice(slice_number, orientation);
            end
            if (orientation ~= PTKImageOrientation.Axial)
                image_slice = image_slice';
            end
        end
        
    end
    
end