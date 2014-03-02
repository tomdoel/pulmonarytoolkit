classdef PTKText < PTKUserInterfaceObject
    % PTKText. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKText is used to build a text control which can be clicked
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
        HorizontalAlignment
        SelectedColour = [1, 0.45, 0]
    end
    
    properties (Access = private)
        Text
        Tag
        ToolTip
        Selected
    end
    
    events
        TextClicked
    end
    
    methods
        function obj = PTKText(parent, text, tooltip, tag)
            obj = obj@PTKUserInterfaceObject(parent);
            obj.Text = text;
            obj.ToolTip = tooltip;
            obj.Tag = tag;
            obj.FontSize = 11;
            obj.HorizontalAlignment = 'left';
            obj.Selected = false;
        end
        
        function delete(obj)
        end
        
        function Select(obj, selected)
            if (selected ~= obj.Selected)
                obj.Selected = selected;
                if ~isempty(obj.GraphicalComponentHandle)
                    if obj.Selected
                        background_colour = obj.SelectedColour;
                    else
                        background_colour = PTKSoftwareInfo.BackgroundColour;
                    end
                    set(obj.GraphicalComponentHandle, 'BackgroundColor', background_colour);
                end
            end
        end
        
        function CreateGuiComponent(obj, position, reporting)
            text_size = [position(1), position(2), position(3), position(4)];
            if obj.Selected
                background_colour =  obj.SelectedColour;
            else
                background_colour = PTKSoftwareInfo.BackgroundColour;
            end
            
            obj.GraphicalComponentHandle = uicontrol('Style', 'text', 'Parent', obj.Parent.GetContainerHandle(reporting), 'Units', 'pixels', 'String', obj.Text, ...
                'Tag', obj.Tag, 'ToolTipString', obj.ToolTip, ...
                'BackgroundColor', background_colour, ...
                'FontAngle', 'normal', 'ForegroundColor', 'white', 'FontUnits', 'pixels', 'FontSize', obj.FontSize, ...
                'HorizontalAlignment', obj.HorizontalAlignment, 'Position', text_size, 'Enable', 'inactive');
        end
    end
    
    methods (Access = protected)
        
        function input_has_been_processed = MouseDown(obj, click_point, selection_type, src)
            % This method is called when the mouse is clicked inside the control
            input_has_been_processed = true;
            notify(obj, 'TextClicked');
        end
        
    end
end