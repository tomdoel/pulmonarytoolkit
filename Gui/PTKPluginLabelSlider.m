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
    end
    
    methods
        function obj = PTKPluginLabelSlider(parent, tool, icon, gui_app, reporting)
            obj = obj@PTKLabelSlider(parent, tool.ButtonText, tool.ToolTip, class(tool), icon, reporting);
            obj.GuiApp = gui_app;
            obj.Tool = tool;
            
            [instance_handle, property_name] = tool.GetHandleAndProperty(gui_app);
            value = instance_handle.(property_name);
            
            obj.Slider.SetSliderLimits(tool.MinValue, tool.MaxValue);
            obj.Slider.SetSliderSteps([tool.SmallStep, tool.LargeStep]);
            obj.Slider.SetSliderValue(value);
            
            obj.AddPostSetListener(instance_handle, property_name, @obj.SliderChangedCallback);
        end

        function enabled = UpdateToolEnabled(obj, gui_app)
            enabled = obj.Tool.IsEnabled(gui_app);
        end
    end
    
    methods (Access = protected)
        function SliderCallback(obj, hObject, arg2)
            SliderCallback@PTKLabelSlider(obj, hObject, arg2);
            
            [instance_handle, property_name] = obj.Tool.GetHandleAndProperty(obj.GuiApp);
            
            value = obj.Slider.SliderValue;
            instance_handle.(property_name) = value;
        end
        
        function SliderChangedCallback(obj, ~, ~, ~)
            [instance_handle, property_name] = obj.Tool.GetHandleAndProperty(obj.GuiApp);
            value = instance_handle.(property_name);            
            obj.Slider.SetSliderValue(value);            
        end
    end    
end