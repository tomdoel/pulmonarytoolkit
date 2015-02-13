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
        
    end
    
    methods (Access = protected, Static)
        
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
        
    end
    
    methods (Access = private, Static)
        
    
        function [rgb_image, alpha] = GetBWImage(image)
            rgb_image = (cat(3, image, image, image));
            alpha = ones(size(image));
        end
        
        function [rgb_image, alpha] = GetLabeledImage(image, map)
            ptk_colormap = PTKSoftwareInfo.Colormap;
            if isempty(map)
                if isa(image, 'double') || isa(image, 'single')
                    rgb_image = label2rgb(round(image), ptk_colormap);
                else
                    rgb_image = label2rgb(image, ptk_colormap);
                end
            else
                if isa(image, 'double') || isa(image, 'single')
                    rgb_image = label2rgb(map(round(image + 1)), ptk_colormap);
                else
                    rgb_image = label2rgb(map(image + 1), ptk_colormap);
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
    end
    
end