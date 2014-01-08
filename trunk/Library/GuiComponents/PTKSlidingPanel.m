classdef PTKSlidingPanel < PTKPanel
    % PTKSlidingPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKSlidingPanel is used to build a sliding panel, where the panel can
    %     be scrolled vertically.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = protected)
        FloatingPanel
        MinYVisible
        MaxYVisible
    end
    
    properties (Access = private)
        FloatingPanelYPosition
        Slider
        SliderValueChangedListener
    end
    
    methods
        function obj = PTKSlidingPanel(parent_handle, reporting)
            obj = obj@PTKPanel(parent_handle, reporting);
            obj.Slider = PTKSlider(obj);
            obj.AddChild(obj.Slider);
            obj.FloatingPanelYPosition = 0;
            obj.SliderValueChangedListener = addlistener(obj.Slider, 'SliderValueChanged', @obj.SliderValueChanged);
        end
        
        function delete(obj)
            delete(obj.SliderValueChangedListener);
        end
        
        function Resize(obj, fixed_panel_size)
            
            % Resize the fixed panel
            Resize@PTKPanel(obj, fixed_panel_size);
            
            % The panel height will affect the slider limits and hence its
            % value
            obj.AutoAdjustSliderLimits;
            
            % Position the slider bar
            obj.Slider.Resize([fixed_panel_size(3) - PTKSlider.SliderWidth + 1, 1, PTKSlider.SliderWidth, fixed_panel_size(4)]);

            % Resize the floating panel. Note this uses the slider position,
            % therefore the slider update should happen first
            obj.UpdateFloatingPanelPosition;
        end
        
        function input_has_been_processed = Scroll(obj, scroll_count, current_point)
            % Called when the mousewheel is used to scroll
            fixed_panel_position = obj.Position;
            
            if (current_point(1) >= fixed_panel_position(1) && current_point(2) >= fixed_panel_position(2) && ...
                    current_point(1) <= fixed_panel_position(1) + fixed_panel_position(3) && ...
                    current_point(2) <= fixed_panel_position(2) + fixed_panel_position(4))
                
                % positive scroll_count = scroll down
                current_value = obj.FloatingPanelYPosition;
                current_value = current_value + 2*scroll_count;
                current_value = min(current_value, obj.FloatingPanel.GetRequestedHeight);
                current_value = max(current_value, 1);
                
                obj.ScrollPanelToThisYPosition(current_value);
                input_has_been_processed = true;
            else
                input_has_been_processed = false;
            end
        end
    end
    
    methods (Access = protected)
        
        function ScrollPanelToThisYPosition(obj, y_top)
            % Moves the sliding panel so that the location y_top is visible at
            % the top of the panel. y_top is measured from the top of the
            % floating panel in pixels.
            
            % The base of the floating panel never goes beyond the bottom of the
            % fixed panel
            y_top = min(y_top, obj.GetSliderRange);
            
            obj.FloatingPanelYPosition = y_top;
            obj.SetSliderFromFloatingPanelYPosition;
            obj.UpdateFloatingPanelPosition;
            
        end
        
    end
    
    methods (Access = private)
        
        function SetSliderFromFloatingPanelYPosition(obj)
            slider_max = obj.GetSliderRange;
            new_slider_value = max(0, slider_max - obj.FloatingPanelYPosition);
            obj.Slider.SetSliderValue(new_slider_value);
        end
        
        function SetFloatingPanelYPositionFromSlider(obj)
            slider_max = obj.GetSliderRange;
            new_y_position = slider_max - obj.Slider.SliderValue;
            obj.FloatingPanelYPosition = new_y_position;
        end
        
        function range = GetSliderRange(obj)
            fixed_panel_height = obj.Position(4);
            floating_panel_height = obj.FloatingPanel.GetRequestedHeight;
            range = max(0, floating_panel_height - fixed_panel_height);
        end
        
        function SliderValueChanged(obj, ~, ~)
            obj.SetFloatingPanelYPositionFromSlider;
            obj.UpdateFloatingPanelPosition;
        end        
        
        
        function UpdateFloatingPanelPosition(obj)
            
            fixed_panel_size = obj.Position;
            
            floating_panel_height = obj.FloatingPanel.GetRequestedHeight;
            overlap_height = max(0, floating_panel_height - fixed_panel_size(4));
            
            slider_is_visible = overlap_height > 0;
            
            floating_panel_width = fixed_panel_size(3);
            if slider_is_visible
                floating_panel_width = floating_panel_width - PTKSlider.SliderWidth;
                
                y_pos = obj.FloatingPanelYPosition - overlap_height;
            else
                y_pos = 1 + fixed_panel_size(4) - floating_panel_height;
            end

            visible_floating_panel_height = fixed_panel_size(4) - y_pos;
            floating_panel_position = [1, y_pos, floating_panel_width, visible_floating_panel_height];
            obj.FloatingPanel.Resize(floating_panel_position);

        end

        function AutoAdjustSliderLimits(obj)
            fixed_panel_size = obj.Parent.Position;
            fixed_panel_height = fixed_panel_size(4);
            floating_panel_height = obj.FloatingPanel.GetRequestedHeight;
            overlap_height = max(0, floating_panel_height - fixed_panel_height);
            
            slider_min = 0;
            slider_max = max(1, overlap_height);
            new_steps = [min(1, 30/(overlap_height - 0)), 300/(overlap_height - 0)];
            obj.Slider.SetSliderLimits(slider_min, slider_max);
            obj.Slider.SetSliderSteps(new_steps);
            
            obj.SetSliderFromFloatingPanelYPosition;
            
            if overlap_height > 0
                obj.Slider.Enable(obj.Reporting);
            else
                obj.Slider.Disable;
            end
            
        end
        
    end
end