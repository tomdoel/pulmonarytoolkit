classdef PTKCheckbox < PTKUserInterfaceObject
    % PTKCheckbox. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKCheckbox is used to build a check box control
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
        function obj = PTKCheckbox(parent, text, tooltip, tag)
            obj = obj@PTKUserInterfaceObject(parent);
            obj.Text = text;
            obj.ToolTip = tooltip;
            obj.Tag = tag;
            obj.FontSize = 11;
            obj.HorizontalAlignment = 'left';
            obj.Checked = false;
            obj.FontColour = PTKSoftwareInfo.TextPrimaryColour;
            obj.BackgroundColour = PTKSoftwareInfo.BackgroundColour;
        end
        
        function CreateGuiComponent(obj, position, reporting)
            obj.GraphicalComponentHandle = uicontrol('Style', 'checkbox', 'Parent', obj.Parent.GetContainerHandle(reporting), ...
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
            notify(obj, 'CheckChanged', PTKEventData(checked));
        end
    end
end