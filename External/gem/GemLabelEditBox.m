classdef GemLabelEditBox < GemVirtualPanel
    % GemLabelEditBox GEM class for an edit box with label text
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = protected)
        Text
        EditBox
    end

    properties
        LabelWidth = 50
        LabelHeight = 20
        EditBoxWidth = 50
        EditBoxHeight = 20
        
        
        TextHeight = 15
        VerticalSpacing = 2
        LabelFontSize = 9
        EditBoxFontSize = 9
        EditBoxSpacing = 6
        EditBoxPosition
        
        StackVertically = false % When multiple controls are grouped, should they be stacked vertically or horizontally?
    end
    
    methods
        function obj = GemLabelEditBox(parent, text, tooltip, tag)
            obj = obj@GemVirtualPanel(parent);
            
            label_horizontal_alignment = 'center';
            
            obj.EditBox = GemEditBox(parent, tooltip);
            obj.AddChild(obj.EditBox);
            obj.AddEventListener(obj.EditBox, 'TextChanged', @obj.EditBoxCallback);
            obj.EditBox.HorizontalAlignment = 'left';
            obj.EditBox.FontSize = obj.EditBoxFontSize;
            text = [text ':'];
            
            obj.Text = GemText(parent, text, tooltip, tag);
            obj.Text.HorizontalAlignment = label_horizontal_alignment;
            obj.Text.FontSize = obj.LabelFontSize;
            obj.AddChild(obj.Text);
        end
       
        function Resize(obj, new_position)
            Resize@GemVirtualPanel(obj, new_position);
            
            control_width = round(new_position(3)/2);
            label_y_position = new_position(2) + obj.VerticalSpacing;
            label_x_position = new_position(1) + control_width - obj.LabelWidth;
            obj.Text.Resize([label_x_position, label_y_position, obj.LabelWidth, obj.LabelHeight]);
            
            edit_y_position = new_position(2) + obj.VerticalSpacing;
            edit_x_position = new_position(1) + control_width;
            obj.EditBox.Resize([edit_x_position, edit_y_position, obj.EditBoxWidth, obj.EditBoxHeight]);
        end
        
        function width = GetWidth(obj)
            width = obj.LabelWidth + obj.LabelWidth;
        end
        
        function height = GetRequestedHeight(obj, width)
            height = max(obj.EditBoxHeight, obj.LabelHeight);
        end

        function Enable(obj)
            Enable@GemVirtualPanel(obj);
            obj.Text.Enable;
            obj.EditBox.Enable;
        end
        
        function Disable(obj)
            Disable@GemVirtualPanel(obj);
            obj.Text.Disable;
            obj.EditBox.Disable;
        end
        
        function Select(obj, is_selected)
        end
        
    end
    
    methods (Access = protected)
        function EditBoxCallback(obj, hObject, ~)
        end
    end
end