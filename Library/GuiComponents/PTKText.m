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
        FontColour
        HorizontalAlignment
        SelectedColour
        SelectedFontColour
        Clickable
    end
    
    properties (Access = private)
        Text
        Tag
        ToolTip
        Selected
        Highlighted
    end
    
    events
        TextClicked
        TextRightClicked
        TextShiftClicked
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
            obj.Highlighted = false;
            obj.FontColour = PTKSoftwareInfo.TextPrimaryColour;
            obj.SelectedColour = PTKSoftwareInfo.SelectedBackgroundColour;
            obj.SelectedFontColour = PTKSoftwareInfo.TextContrastColour;
            
            obj.Clickable = true;
        end
        
        function Select(obj, selected)
            if (selected ~= obj.Selected)
                obj.Selected = selected;
                obj.UpdateBackgroundColour;
            end
        end
        
        function Highlight(obj, highlighted)
            if (highlighted ~= obj.Highlighted)
                obj.Highlighted = highlighted;
                obj.UpdateBackgroundColour;
            end
        end
        
        function CreateGuiComponent(obj, position, reporting)
            text_size = [position(1), position(2), position(3), position(4)];
            if obj.Selected
                background_colour =  obj.SelectedColour;
                text_colour = obj.SelectedFontColour;
            else
                background_colour = PTKSoftwareInfo.BackgroundColour;
                text_colour = obj.FontColour;
            end
            
            obj.GraphicalComponentHandle = uicontrol('Style', 'text', 'Parent', obj.Parent.GetContainerHandle(reporting), 'Units', 'pixels', 'String', obj.Text, ...
                'Tag', obj.Tag, 'ToolTipString', obj.ToolTip, ...
                'BackgroundColor', background_colour, ...
                'FontAngle', 'normal', 'ForegroundColor', text_colour, 'FontUnits', 'pixels', 'FontSize', obj.FontSize, ...
                'HorizontalAlignment', obj.HorizontalAlignment, ...
                'Position', text_size, 'Enable', 'inactive');
        end
        
        function ChangeText(obj, new_text)
            obj.Text = new_text;
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                set(obj.GraphicalComponentHandle, 'String', new_text);
            end
        end
    end
    
    methods (Access = protected)
        
        function input_has_been_processed = MouseDown(obj, click_point, selection_type, src)
            % This method is called when the mouse is clicked inside the control

            if ~obj.Clickable
                input_has_been_processed = false;
                return;
            end
            
            input_has_been_processed = true;
            
            if strcmp(selection_type, 'extend')
                notify(obj, 'TextShiftClicked', PTKEventData(obj.Tag));
            elseif strcmp(selection_type, 'alt')
                notify(obj, 'TextRightClicked', PTKEventData(obj.Tag));
            else
                notify(obj, 'TextClicked', PTKEventData(obj.Tag));
            end
        end
        
        function UpdateBackgroundColour(obj)
            if ~isempty(obj.GraphicalComponentHandle)
                if obj.Selected
                    background_colour = obj.SelectedColour;
                    text_colour = obj.SelectedFontColour;
                else
                    background_colour = PTKSoftwareInfo.BackgroundColour;
                    text_colour = obj.FontColour;
                end

                if obj.Highlighted
                    background_colour = min(1, background_colour + 0.2);
                end
                set(obj.GraphicalComponentHandle, 'BackgroundColor', background_colour, 'ForegroundColor', text_colour);
            end
        end
    end
end