classdef PTKButton < PTKUserInterfaceObject
    % PTKButton. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKButton is used to build a button control
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
        BackgroundColour = [0, 0, 0]
        
        Selected = false
        Highlighted = false;
        
        ShowTextOnButton
        
        SelectedColour = uint8(255*(PTKSoftwareInfo.SelectedBackgroundColour));
        UnSelectedColour = uint8([150, 150, 150]);
    end
    
    events
        ButtonClicked
    end
    
    properties (Access = protected)
        Tag
        Callback
    end
    
    methods
        function obj = PTKButton(parent, text, tooltip, tag, callback)
            obj = obj@PTKUserInterfaceObject(parent);
            obj.Text = text;
            obj.ToolTip = tooltip;
            obj.Tag = tag;
            obj.Callback = callback;
            obj.ShowTextOnButton = true;
        end
        
        function AddAndResizeImage(obj, new_image)
            if isempty(new_image)
                obj.RGBImage = [];
            else
                new_image_size = [obj.ButtonHeight - 2*obj.BorderSize, obj.ButtonWidth - 2*obj.BorderSize];
                rgb_image = zeros([obj.ButtonHeight, obj.ButtonWidth, 3], class(new_image));
                rgb_image(1+obj.BorderSize:end-obj.BorderSize, 1+obj.BorderSize:end-obj.BorderSize, 1) = imresize(new_image(:, :, 1), new_image_size, 'bilinear');
                rgb_image(1+obj.BorderSize:end-obj.BorderSize, 1+obj.BorderSize:end-obj.BorderSize, 2) = imresize(new_image(:, :, 2), new_image_size, 'bilinear');
                rgb_image(1+obj.BorderSize:end-obj.BorderSize, 1+obj.BorderSize:end-obj.BorderSize, 3) = imresize(new_image(:, :, 3), new_image_size, 'bilinear');
                mask_image = ones(size(rgb_image));
                rgb_image = PTKImageUtilities.AddBorderToRGBImage(rgb_image, mask_image, obj.BorderSize, obj.BackgroundColour, obj.UnSelectedColour, obj.UnSelectedColour, obj.BackgroundColour);
                obj.RGBImage = rgb_image;
            end
        end
        
        function CreateGuiComponent(obj, position, reporting)
            
            % If no image gas been specified then create a blank image
            if isempty(obj.RGBImage)
                obj.RGBImage = PTKImageUtilities.GetButtonImage([], position(3), position(4), [], [], obj.BorderSize, obj.BackgroundColour, obj.UnSelectedColour);
            end
            
            if obj.ShowTextOnButton
                button_text = obj.Text;
            else
                button_text = '';
            end
            
            obj.GraphicalComponentHandle = uicontrol('Style', 'pushbutton', 'Parent', obj.Parent.GetContainerHandle(reporting), ...
                'String', button_text, 'Tag', obj.Tag, 'ToolTipString', obj.ToolTip, ...
                'FontAngle', obj.FontAngle, 'ForegroundColor', 'white', 'FontUnits', 'pixels', 'FontSize', obj.FontSize, ...
                'Callback', @obj.ButtonClickedCallback, 'Position', position, 'CData', obj.RGBImage);
        end
        
        function ChangeImage(obj, preview_image, window, level)
            if isempty(obj.Position)
                button_size = [obj.ButtonWidth, obj.ButtonHeight];
            else
                button_size = obj.Position(3:4);
            end
            obj.RGBImage = PTKImageUtilities.GetButtonImage(preview_image, button_size(1), button_size(2), window, level, 1, obj.BackgroundColour, obj.UnSelectedColour);
            if obj.ComponentHasBeenCreated
                set(obj.GraphicalComponentHandle, 'CData', obj.RGBImage);
            end
        end
        
        function Select(obj, is_selected)
            if obj.Selected ~= is_selected
                obj.Selected = is_selected;
                obj.UpdateBackgroundColour;
            end
        end        
    end
    
    methods (Access = protected)
        function ButtonClickedCallback(obj, ~, ~)
            obj.Select(true);
            notify(obj, 'ButtonClicked', PTKEventData(obj.Tag));
            obj.Callback(obj.Tag);
            
            % It is possible that the callback may lead to a rebuild of the interface and
            % thus deletion of the button that triggered the callback; in which case we
            % can't continue with the select
            if isvalid(obj)
                obj.Select(false);
            end
        end
        
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src)
            % This method is called when the mouse is moved

            obj.Highlight(true);
            input_has_been_processed = true;
        end

        function input_has_been_processed = MouseExit(obj, click_point, selection_type, src)
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
                obj.UpdateBackgroundColour;
            end            
        end
        
        function UpdateBackgroundColour(obj)
            mask_image = ones(size(obj.RGBImage));
            if obj.Selected
                border_colour = obj.SelectedColour;
            else
                border_colour = obj.UnSelectedColour;
            end
            
            if obj.Highlighted
                border_colour = min(255, border_colour + 100);
            end
            
            if ~isempty(obj.RGBImage)
                obj.RGBImage = PTKImageUtilities.AddBorderToRGBImage(obj.RGBImage, mask_image, obj.BorderSize, obj.BackgroundColour, obj.UnSelectedColour, border_colour, obj.BackgroundColour);
            end
            
            if obj.ComponentHasBeenCreated
                set(obj.GraphicalComponentHandle, 'CData', obj.RGBImage);
            end
        end        
    end
end