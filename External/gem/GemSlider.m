classdef GemSlider < GemUserInterfaceObject
    % GemSlider GEM class for building a slider control
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
        
    properties (SetAccess = private)        
        SliderPosition
        SliderValue
        SliderMin
        SliderMax
        SliderSteps
        
        SliderValueSetInProgress % Used to stop a forced change in the slider value triggering a change notification
    end
    
    properties
        IsHorizontal
        StackVertically % When multiple GemSliders are grouped, should they be stacked vertically or horizontally?
    end
    
    properties (Constant)
        SliderWidth = 15
    end
    
    events
        SliderValueChanged % The slider value has been changed by the user
    end
    
    methods
        function obj = GemSlider(parent)
            obj = obj@GemUserInterfaceObject(parent);
            obj.SliderValue = 0;
            obj.SliderMin = 0;
            obj.SliderMax = 100;
            obj.SliderSteps = [1, 10];
            obj.SliderValueSetInProgress = false;
            obj.IsHorizontal = false;
            obj.StackVertically = false;
        end

        function CreateGuiComponent(obj, position)
            % Create the sider
            obj.GraphicalComponentHandle = uicontrol('Style', 'slider', 'Parent', obj.Parent.GetContainerHandle, 'Units', 'pixels', 'Position', position, 'Min', obj.SliderMin, 'Max', obj.SliderMax, 'SliderStep', obj.SliderSteps, 'Value', obj.SliderValue);
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
            min = double(min);
            max = double(max);
            obj.SliderMin = min;
            obj.SliderMax = max;
            if obj.ComponentHasBeenCreated
                set(obj.GraphicalComponentHandle, 'Min', min, 'Max', max);
            end
        end
        
        function SetSliderSteps(obj, steps)
            steps = double(steps);
            obj.SliderSteps = steps;
            if obj.ComponentHasBeenCreated()
                set(obj.GraphicalComponentHandle, 'SliderStep', steps);
            end
        end
        
        function Resize(obj, position)
            
            % In Matlab, the orientation of the slider depends on whether the width is
            % greater than the height. We however want to ensure the slider maintains its
            % correct orientation as the GUI is resized
            if obj.IsHorizontal
                if position(3) < position(4)
                    position(4) = max(1, position(3) - 1);
                end
            else
                if position(4) < position(3)
                    position(3) = max(1, position(4) - 1);
                end                    
            end
            Resize@GemUserInterfaceObject(obj, position);
        end        
        
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