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
    end

    properties
        SliderWidth = 150
        SliderHeight = 50
        TextHeight = 25
        VerticalSpacing = 2
        SliderHorizontalSpacing = 0
        LabelFontSize = 9
        SliderValue = 0
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
            obj.Text = PTKText(parent, text, tooltip, tag);
            obj.Text.HorizontalAlignment = 'center';
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
            obj.Text.Resize([new_position(1), new_position(2), text_width, obj.TextHeight]);
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
        end
        
        function Disable(obj)
            Disable@PTKVirtualPanel(obj);
            obj.Slider.Disable;
            obj.Text.Disable;
        end
        
        function Select(obj, is_selected)
        end
        
    end
    
    methods (Access = protected)
        function SliderCallback(obj, hObject, ~)
        end
    end
end