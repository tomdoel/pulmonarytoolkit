classdef GemLabelSlider < GemVirtualPanel
    % GemLabelSlider GEM class for a slider control with label text below
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = protected)
        Slider
        Text
        EditBox
    end

    properties
        SliderWidth = 100
        SliderHeight = 50
        TextHeight = 15
        VerticalSpacing = 2
        SliderHorizontalSpacing = 10
        LabelFontSize = 9
        EditBoxFontSize = 9
        SliderValue = 0
        EditBoxSpacing = 6
        EditBoxHeight = 15
        EditBoxPosition
        
        ShowEditBox = true
        EditBoxWidth
        StackVertically = false % When multiple GemSliders are grouped, should they be stacked vertically or horizontally?
    end
    
    events
        SliderValueChanged
    end
    
    methods
        function obj = GemLabelSlider(parent, text, tooltip, tag)
            obj = obj@GemVirtualPanel(parent);
            obj.Slider = GemSlider(parent);
            obj.Slider.IsHorizontal = true;
            obj.AddChild(obj.Slider);
            
            label_horizontal_alignment = 'center';
            
            if obj.ShowEditBox
                obj.EditBox = GemEditBox(parent, tooltip);
                obj.AddChild(obj.EditBox);
                obj.AddEventListener(obj.EditBox, 'TextChanged', @obj.EditBoxCallback);
                label_horizontal_alignment = 'right';
                obj.EditBox.HorizontalAlignment = 'left';
                obj.EditBox.FontSize = obj.EditBoxFontSize;
                text = [text ':'];
            end
            
            obj.Text = GemText(parent, text, tooltip, tag);
            obj.Text.HorizontalAlignment = label_horizontal_alignment;
            obj.Text.FontSize = obj.LabelFontSize;
            obj.AddChild(obj.Text);
            
            obj.AddEventListener(obj.Slider, 'SliderValueChanged', @obj.SliderCallback);            
        end
       
        function Resize(obj, new_position)
            Resize@GemVirtualPanel(obj, new_position);
            
            slider_x_pos = new_position(1) + obj.SliderHorizontalSpacing;
            slider_width = obj.SliderWidth;
            text_width = slider_width + 2*obj.SliderHorizontalSpacing;
            slider_y_pos = new_position(2) + obj.TextHeight + obj.VerticalSpacing;
            slider_height = obj.Slider.SliderWidth;
            obj.Slider.Resize([slider_x_pos, slider_y_pos, slider_width, slider_height]);
            if isempty(obj.EditBox)
                obj.Text.Resize([new_position(1), new_position(2), text_width, obj.TextHeight]);
            else
                if isempty(obj.EditBoxPosition)
                    adjusted_text_width = max(1, round(text_width/2 - obj.EditBoxSpacing/2));
                    editbox_x_offset = round(text_width/2 + obj.EditBoxSpacing/2);
                    editbox_width = round(text_width/2 - obj.EditBoxSpacing/2);
                else
                    adjusted_text_width = max(1, obj.EditBoxPosition - obj.EditBoxSpacing);
                    editbox_x_offset = obj.EditBoxPosition;
                    editbox_width = round(text_width - obj.EditBoxPosition);
                end
                if ~isempty(obj.EditBoxWidth)
                    editbox_width = obj.EditBoxWidth;
                end
                editbox_y_position = new_position(2) + (obj.TextHeight - obj.EditBoxHeight);
                new_text_position = [new_position(1), new_position(2), adjusted_text_width, obj.TextHeight];
                new_edit_box_position = [new_position(1) + editbox_x_offset, editbox_y_position, editbox_width, obj.EditBoxHeight];
                obj.Text.Resize(new_text_position);
                obj.EditBox.Resize(new_edit_box_position);
            end
            
        end
        
        function width = GetWidth(obj)
            width = obj.SliderWidth + 2*obj.SliderHorizontalSpacing;
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.Slider.SliderWidth + obj.TextHeight + obj.VerticalSpacing;
        end

        function Enable(obj)
            Enable@GemVirtualPanel(obj);
            obj.Slider.Enable;
            obj.Text.Enable;
            if ~isempty(obj.EditBox)
                obj.EditBox.Enable;
            end
        end
        
        function Disable(obj)
            Disable@GemVirtualPanel(obj);
            obj.Slider.Disable;
            obj.Text.Disable;
            if ~isempty(obj.EditBox)
                obj.EditBox.Disable;
            end
        end
        
        function Select(obj, is_selected)
        end
        
    end
    
    methods (Access = protected)
        function SliderCallback(obj, hObject, ~)
        end

        function EditBoxCallback(obj, hObject, ~)
        end
    end
end