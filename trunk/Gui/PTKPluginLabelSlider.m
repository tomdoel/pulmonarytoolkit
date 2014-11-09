classdef PTKPluginLabelSlider < PTKLabelSlider
    % PTKPluginLabelSlider. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPluginLabelSlider is used to build a slider control which interacts
    %     with the PTK GUI
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        GuiApp
        Tool
        FixToInteger = true
    end
    
    methods
        function obj = PTKPluginLabelSlider(parent, tool, icon, gui_app, reporting)
            obj = obj@PTKLabelSlider(parent, tool.ButtonText, tool.ToolTip, class(tool), icon, reporting);
            obj.GuiApp = gui_app;
            obj.Tool = tool;
            
            [instance_handle, value_property_name, limits_property_name] = tool.GetHandleAndProperty(gui_app);
            value = instance_handle.(value_property_name);
            
            if ~isempty(limits_property_name)
                limits = instance_handle.(limits_property_name);
                if ~isempty(limits)
                    min_slider = limits(1);
                    max_slider = limits(2);
                else
                    min_slider = tool.MinValue;
                    max_slider = tool.MaxValue;
                end
            else
                min_slider = tool.MinValue;
                max_slider = tool.MaxValue;
            end
            
            obj.Slider.SetSliderLimits(min_slider, max_slider);
            obj.Slider.SetSliderSteps([tool.SmallStep, tool.LargeStep]);
            obj.Slider.SetSliderValue(value);
            
            obj.EditBoxPosition = tool.EditBoxPosition;
            obj.EditBoxWidth = tool.EditBoxWidth;
            
            if ~isempty(obj.EditBox)
                obj.EditBox.SetText(num2str(value, '%.6g'));
            end
            
            obj.AddPostSetListener(instance_handle, value_property_name, @obj.PropertyChangedCallback);
            
            if ~isempty(limits_property_name)
                obj.AddPostSetListener(instance_handle, limits_property_name, @obj.PropertyLimitsChangedCallback);
            end
        end

        function enabled = UpdateToolEnabled(obj, gui_app)
            enabled = obj.Tool.IsEnabled(gui_app);
        end
    end
    
    methods (Access = protected)
        function SliderCallback(obj, hObject, arg2)
            SliderCallback@PTKLabelSlider(obj, hObject, arg2);
            
            [instance_handle, value_property_name, ~] = obj.Tool.GetHandleAndProperty(obj.GuiApp);
            
            value = obj.Slider.SliderValue;
            if obj.FixToInteger
                value = round(value);
            end
            instance_handle.(value_property_name) = value;
            obj.EditBox.SetText(num2str(value, '%.6g'));
        end
        
        function EditBoxCallback(obj, hObject, arg2)
            EditBoxCallback@PTKLabelSlider(obj, hObject, arg2);
            
            [instance_handle, value_property_name, ~] = obj.Tool.GetHandleAndProperty(obj.GuiApp);
            
            value = round(str2double(obj.EditBox.Text));
            instance_handle.(value_property_name) = value;
            obj.Slider.SetSliderValue(value);
        end
        
        function PropertyChangedCallback(obj, ~, ~, ~)
            [instance_handle, value_property_name, ~] = obj.Tool.GetHandleAndProperty(obj.GuiApp);
            value = instance_handle.(value_property_name);            
            obj.Slider.SetSliderValue(value);
            obj.EditBox.SetText(num2str(value, '%.6g'));
        end
        
        function PropertyLimitsChangedCallback(obj, ~, ~, ~)
            [instance_handle, ~, limits_property_name] = obj.Tool.GetHandleAndProperty(obj.GuiApp);
            limits = instance_handle.(limits_property_name);            
            obj.Slider.SetSliderLimits(limits(1), limits(2));
            range = limits(2) - limits(1);
            if abs(range) >= 100
                obj.FixToInteger = true;
            else
                obj.FixToInteger = false;
            end
        end
        
    end    
end