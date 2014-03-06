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
        FontAngle = 'normal'
        Text
        ToolTip
        RGBImage
        BackgroundColour
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
            obj.BackgroundColour = [0, 0, 0];
        end
        
        function CreateGuiComponent(obj, position, reporting)
            
            % If no image gas been specified then create a blank image
            if isempty(obj.RGBImage)
                obj.RGBImage = PTKImageUtilities.GetButtonImage([], position(3), position(4), [], [], 1, obj.BackgroundColour);
            end
            
            obj.GraphicalComponentHandle = uicontrol('Style', 'pushbutton', 'Parent', obj.Parent.GetContainerHandle(reporting), ...
                'String', obj.Text, 'Tag', obj.Tag, 'ToolTipString', obj.ToolTip, ...
                'FontAngle', obj.FontAngle, 'ForegroundColor', 'white', 'FontUnits', 'pixels', 'FontSize', obj.FontSize, ...
                'Callback', @obj.ButtonClicked, 'Position', position, 'CData', obj.RGBImage);            
        end
        
        function ChangeImage(obj, preview_image, window, level)
            if isempty(obj.Position)
                button_size = [obj.ButtonWidth, obj.ButtonHeight];
            else
                button_size = obj.Position(3:4);
            end
            obj.RGBImage = PTKImageUtilities.GetButtonImage(preview_image, button_size(1), button_size(2), window, level, 1, obj.BackgroundColour);
            if obj.ComponentHasBeenCreated
                set(obj.GraphicalComponentHandle, 'CData', obj.RGBImage);
            end
        end
        
    end
    
    methods (Access = protected)
        function ButtonClicked(obj, ~, ~)
            obj.Callback(obj.Tag);
        end        
    end
end