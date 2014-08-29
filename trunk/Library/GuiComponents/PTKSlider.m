classdef PTKSlider < PTKUserInterfaceObject
    % PTKSlider. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKSlider is used to build a slider control
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties (SetAccess = private)        
        SliderPosition
        SliderValue
        SliderMin
        SliderMax
        SliderSteps
        
        SliderValueSetInProgress % Used to stop a forced change in the slider value triggering a change notification
    end
    
    properties (Constant)
        SliderWidth = 15
    end
    
    events
        SliderValueChanged % The slider value has been changed by the user
    end
    
    methods
        function obj = PTKSlider(parent)
            obj = obj@PTKUserInterfaceObject(parent);
            obj.SliderValue = 0;
            obj.SliderMin = 0;
            obj.SliderMax = 100;
            obj.SliderSteps = [1, 10];
            obj.SliderValueSetInProgress = false;
        end

        function CreateGuiComponent(obj, position, reporting)
            % Create the sider
            obj.GraphicalComponentHandle = uicontrol('Style', 'slider', 'Parent', obj.Parent.GetContainerHandle(reporting), 'Units', 'pixels', 'Value', 0, 'Position', position, 'Min', obj.SliderMin, 'Max', obj.SliderMax, 'SliderStep', obj.SliderSteps);
            obj.AddEventListener(obj.GraphicalComponentHandle, 'ContinuousValueChange', @obj.SliderCallback);
        end
        
        function SetSliderValue(obj, value)
            obj.SliderValue = value;
            if obj.ComponentHasBeenCreated
                obj.SliderValueSetInProgress = true;
                set(obj.GraphicalComponentHandle, 'Value', value);
                obj.SliderValueSetInProgress = false;
            end
        end
        
        function SetSliderLimits(obj, min, max)
            obj.SliderMin = min;
            obj.SliderMax = max;
            if obj.ComponentHasBeenCreated
                set(obj.GraphicalComponentHandle, 'Min', min, 'Max', max);
            end
        end
        
        function SetSliderSteps(obj, steps)
            obj.SliderSteps = steps;
            if obj.ComponentHasBeenCreated
                set(obj.GraphicalComponentHandle, 'SliderStep', steps);
            end
        end
        
    end
    
    methods (Access = protected)
    end
    
    methods (Access = private)
        
        function SliderCallback(obj, hObject, ~)
            if ~obj.SliderValueSetInProgress
                new_value = get(obj.GraphicalComponentHandle, 'Value');
                obj.SliderValue = new_value;
                notify(obj, 'SliderValueChanged');
            end
        end
        
    end
end