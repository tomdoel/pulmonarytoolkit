classdef GemButton < GemUserInterfaceObject
    % GemButton GEM class for a button control
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties
        % The button width and height may need to be set if an image is to be applied to the button
        % before it is resized
        ButtonWidth
        ButtonHeight

        FontSize = 11
        BorderSize = 1
        FontAngle = 'normal'
        Text
        ToolTip
        RGBImage
        OriginalImage
        ImageHighlight
        BackgroundColour = [0, 0, 0]
        
        Selected = false
        Highlighted = false;
        
        ShowTextOnButton
        
        SelectedColour
        UnSelectedColour
        HighlightColour
        HighlightSelectedColour
        
        AutoUpdateStatus = false
    end
    
    events
        ButtonClicked
    end
    
    properties (Access = protected)
        Tag
        Callback
    end
    
    methods
        function obj = GemButton(parent, text, tooltip, tag, callback)
            obj = obj@GemUserInterfaceObject(parent);
            obj.Text = text;
            obj.ToolTip = tooltip;
            obj.Tag = tag;
            obj.Callback = callback;
            obj.ShowTextOnButton = true;
            obj.SelectedColour = uint8(255*(obj.StyleSheet.SelectedBackgroundColour));
            obj.UnSelectedColour = uint8([150, 150, 150]);
            obj.HighlightColour = min(255, obj.UnSelectedColour + 100);
            obj.HighlightSelectedColour = min(255, obj.SelectedColour + 100);
        end
        
        function AddAndResizeImageWithHighlightMask(obj, new_image, mask_colour_rgb)
            
            if isempty(new_image)
                obj.OriginalImage = [];
            else
                new_image_size = [obj.ButtonHeight - 2*obj.BorderSize, obj.ButtonWidth - 2*obj.BorderSize];
                rgb_image = zeros([obj.ButtonHeight, obj.ButtonWidth, 3], class(new_image));
                rgb_image(1+obj.BorderSize:end-obj.BorderSize, 1+obj.BorderSize:end-obj.BorderSize, 1) = imresize(new_image(:, :, 1), new_image_size, 'bilinear');
                rgb_image(1+obj.BorderSize:end-obj.BorderSize, 1+obj.BorderSize:end-obj.BorderSize, 2) = imresize(new_image(:, :, 2), new_image_size, 'bilinear');
                rgb_image(1+obj.BorderSize:end-obj.BorderSize, 1+obj.BorderSize:end-obj.BorderSize, 3) = imresize(new_image(:, :, 3), new_image_size, 'bilinear');
                background = rgb_image(:, :, 1) == mask_colour_rgb(1) & rgb_image(:, :, 2) == mask_colour_rgb(2) & rgb_image(:, :, 3) == mask_colour_rgb(3);

                obj.ImageHighlight = GemUtilities.GetRGBImageHighlight(rgb_image, mask_colour_rgb);
                
                for index = 1 : 3
                    rgb_slice = rgb_image(:, :, index);
                    rgb_slice(background) = round(255*obj.StyleSheet.BackgroundColour(index));
                    rgb_image(:, :, index) = rgb_slice;
                end
                obj.OriginalImage = rgb_image;
            end
            
            obj.UpdateImageHighlight;
        end
        
        function CreateGuiComponent(obj, position)
            
            % If no image has been specified then create a blank image
            if isempty(obj.OriginalImage)
                obj.OriginalImage = GemUtilities.GetBlankButtonImage(position(3), position(4), obj.BorderSize, obj.BackgroundColour, obj.UnSelectedColour);
                button_size = size(obj.RGBImage);
                obj.ImageHighlight = GemUtilities.GetBorderImage(button_size(1:2), obj.BorderSize);
            end
            
            obj.UpdateRGBImageCache;
            
            if obj.ShowTextOnButton
                button_text = obj.Text;
            else
                button_text = '';
            end
            
            obj.GraphicalComponentHandle = uicontrol('Style', 'pushbutton', 'Parent', obj.Parent.GetContainerHandle, ...
                'String', button_text, 'Tag', obj.Tag, 'ToolTipString', obj.ToolTip, ...
                'FontAngle', obj.FontAngle, 'ForegroundColor', obj.StyleSheet.TextPrimaryColour, 'FontUnits', 'pixels', 'FontSize', obj.FontSize, ...
                'Callback', @obj.ButtonClickedCallback, 'Position', position, 'CData', obj.RGBImage);
        end
        
        function ChangeImage(obj, preview_image)
            obj.OriginalImage = preview_image;
            button_size = size(obj.RGBImage);
            obj.ImageHighlight = GemUtilities.GetBorderImage(button_size(1:2), obj.BorderSize);

            obj.UpdateImageHighlight
        end
        
        function Select(obj, is_selected)
            if obj.Selected ~= is_selected
                obj.Selected = is_selected;
                obj.UpdateImageHighlight;
            end
        end        
    end
    
    methods (Access = protected)
        function ButtonClickedCallback(obj, ~, ~)
            obj.Select(true);
            notify(obj, 'ButtonClicked', CoreEventData(obj.Tag));
            obj.Callback(obj.Tag);
            
            % It is possible that the callback may lead to a rebuild of the interface and
            % thus deletion of the button that triggered the callback; in which case we
            % can't continue with the select
            if isvalid(obj) && ~obj.AutoUpdateStatus
                obj.Select(false);
            end
        end
        
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is moved

            obj.Highlight(true);
            input_has_been_processed = true;
        end

        function input_has_been_processed = MouseExit(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse exits a control which previously
            % processed a MouseHasMoved event
            
            obj.Highlight(false);
            input_has_been_processed = true;
        end
        
    end
    
    methods (Access = private)
        function Highlight(obj, highlighted)
            if (highlighted ~= obj.Highlighted)
                obj.Highlighted = highlighted;
                obj.UpdateImageHighlight;
            end            
        end
        
        function UpdateImageHighlight(obj)
            obj.UpdateRGBImageCache;
            
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                set(obj.GraphicalComponentHandle, 'CData', obj.RGBImage);
            end
        end
        
        function UpdateRGBImageCache(obj)
            % Take the button image from the OriginalImage cache property, and a highlight
            % of the appropriate colour, and then put into the RGBImage cache property
            
            if isempty(obj.OriginalImage)
                obj.RGBImage = [];
            else
                if obj.Selected
                    if obj.Highlighted
                        highlight_colour = obj.HighlightSelectedColour;
                    else
                        highlight_colour = obj.SelectedColour;
                    end
                else
                    if obj.Highlighted
                        highlight_colour = obj.HighlightColour;
                    else
                        highlight_colour = obj.UnSelectedColour;
                    end
                end
                obj.RGBImage = GemUtilities.AddHighlightToRGBImage(obj.OriginalImage, obj.ImageHighlight, highlight_colour);
            end
        end        
    end
end