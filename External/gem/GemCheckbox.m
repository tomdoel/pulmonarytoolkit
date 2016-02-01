classdef GemCheckbox < GemUserInterfaceObject
    % GemCheckbox GEM class for a check box control
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties
        FontSize
        FontColour
        BackgroundColour
        HorizontalAlignment
    end
    
    properties (Access = private)
        Text
        Tag
        ToolTip
        Checked
    end
    
    events
        CheckChanged
    end
    
    methods
        function obj = GemCheckbox(parent, text, tooltip, tag)
            obj = obj@GemUserInterfaceObject(parent);
            obj.Text = text;
            obj.ToolTip = tooltip;
            obj.Tag = tag;
            obj.FontSize = 11;
            obj.HorizontalAlignment = 'left';
            obj.Checked = false;
            obj.FontColour = obj.StyleSheet.TextPrimaryColour;
            obj.BackgroundColour = obj.StyleSheet.BackgroundColour;
        end
        
        function CreateGuiComponent(obj, position)
            obj.GraphicalComponentHandle = uicontrol('Style', 'checkbox', 'Parent', obj.Parent.GetContainerHandle, ...
                'Units', 'pixels', 'Position', position, 'Tag', obj.Tag, 'ToolTipString', obj.ToolTip, ...
                'ForegroundColor', obj.FontColour, 'BackgroundColor', obj.BackgroundColour, ...
                'FontUnits', 'pixels', 'FontSize', obj.FontSize, 'FontAngle', 'normal', ...
                'HorizontalAlignment', obj.HorizontalAlignment, 'String', obj.Text, ...
                'Callback', @obj.CheckboxCallback, 'Value', obj.Checked);
        end
        
        function ChangeChecked(obj, checked)
            obj.Checked = checked;
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                set(obj.GraphicalComponentHandle, 'Value', checked);
            end
        end
    end
    
    methods (Access = protected)
        function CheckboxCallback(obj, hObject, ~, ~)
            checked = get(hObject,'Value');
            obj.Checked = checked;
            notify(obj, 'CheckChanged', CoreEventData(checked));
        end
    end
end