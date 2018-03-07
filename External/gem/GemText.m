 classdef GemText < GemUserInterfaceObject
    % GemText GEM class for a read-only, clickable text object
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
        Bold
        FontColour
        HorizontalAlignment
        SelectedColour
        SelectedFontColour
        Clickable
        BackgroundColour
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
        function obj = GemText(parent, text, tooltip, tag)
            obj = obj@GemUserInterfaceObject(parent);
            obj.Text = text;
            obj.Bold = false;
            obj.ToolTip = tooltip;
            obj.Tag = tag;
            obj.FontSize = 11;
            obj.HorizontalAlignment = 'left';
            obj.Selected = false;
            obj.Highlighted = false;
            obj.FontColour = obj.StyleSheet.TextPrimaryColour;
            obj.SelectedColour = obj.StyleSheet.SelectedBackgroundColour;
            obj.SelectedFontColour = obj.StyleSheet.TextContrastColour;
            obj.BackgroundColour = obj.StyleSheet.BackgroundColour;
            
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
        
        function CreateGuiComponent(obj, position)
            text_size = [position(1), position(2), position(3), position(4)];
            if obj.Selected
                background_colour =  obj.SelectedColour;
                text_colour = obj.SelectedFontColour;
            else
                background_colour = obj.BackgroundColour;
                text_colour = obj.FontColour;
            end
            
            if obj.Bold
                weight = 'bold';
            else
                weight = 'normal';
            end
            
            obj.GraphicalComponentHandle = uicontrol('Style', 'text', 'Parent', obj.Parent.GetContainerHandle, 'Units', 'pixels', 'String', obj.Text, ...
                'Tag', obj.Tag, 'ToolTipString', obj.ToolTip, ...
                'BackgroundColor', background_colour, ...
                'FontAngle', 'normal', 'ForegroundColor', text_colour, 'FontName', obj.StyleSheet.Font, 'FontUnits', 'pixels', 'FontSize', obj.FontSize, ...
                'HorizontalAlignment', obj.HorizontalAlignment, 'FontWeight', weight, ...
                'Position', text_size, 'Enable', 'inactive');
        end
        
        function ChangeText(obj, new_text)
            if ~strcmp(obj.Text, new_text)
                obj.Text = new_text;
                if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                    set(obj.GraphicalComponentHandle, 'String', new_text);
                end
            end
        end
    end
    
    methods (Access = protected)
        
        function input_has_been_processed = MouseDown(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is clicked inside the control

            if ~obj.Clickable
                input_has_been_processed = false;
                return;
            end
            
            input_has_been_processed = true;
            
            if strcmp(selection_type, 'extend')
                notify(obj, 'TextShiftClicked', CoreEventData(obj.Tag));
            elseif strcmp(selection_type, 'alt')
                notify(obj, 'TextRightClicked', CoreEventData(obj.Tag));
            else
                notify(obj, 'TextClicked', CoreEventData(obj.Tag));
            end
        end
        
        function UpdateBackgroundColour(obj)
            if ~isempty(obj.GraphicalComponentHandle)
                if obj.Selected
                    background_colour = obj.SelectedColour;
                    text_colour = obj.SelectedFontColour;
                else
                    background_colour = obj.BackgroundColour;
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