classdef PTKLabelSlider < PTKVirtualPanel
    % PTKLabelSlider. Part of the gui for the Pulmonary Toolkit.
    %
    %     PTKLabelButton is used to display a slider with label text below
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = protected)
        Slider
        Text
        EditBox
    end

    properties
        SliderWidth = 150
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
    end
    
    events
        SliderValueChanged
    end
    
    methods
        function obj = PTKLabelSlider(parent, text, tooltip, tag, icon, reporting)
            obj = obj@PTKVirtualPanel(parent, reporting);
            obj.Slider = PTKSlider(parent);
            obj.Slider.IsHorizontal = true;
            obj.AddChild(obj.Slider, reporting);
            
            label_horizontal_alignment = 'center';
            
            if obj.ShowEditBox
                obj.EditBox = PTKEditBox(parent, tooltip);
                obj.AddChild(obj.EditBox, reporting);
                obj.AddEventListener(obj.EditBox, 'TextChanged', @obj.EditBoxCallback);
                label_horizontal_alignment = 'right';
                obj.EditBox.HorizontalAlignment = 'left';
                obj.EditBox.FontSize = obj.EditBoxFontSize;
                text = [text ':'];
            end
            
            obj.Text = PTKText(parent, text, tooltip, tag);
            obj.Text.HorizontalAlignment = label_horizontal_alignment;
            obj.Text.FontSize = obj.LabelFontSize;
            obj.AddChild(obj.Text, reporting);
            
            obj.AddEventListener(obj.Slider, 'SliderValueChanged', @obj.SliderCallback);            
        end
       
        function Resize(obj, new_position)
            Resize@PTKVirtualPanel(obj, new_position);
            
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

        function Enable(obj, reporting)
            Enable@PTKVirtualPanel(obj, reporting);
            obj.Slider.Enable(reporting);
            obj.Text.Enable(reporting);
            if ~isempty(obj.EditBox)
                obj.EditBox.Enable(reporting);
            end
        end
        
        function Disable(obj)
            Disable@PTKVirtualPanel(obj);
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