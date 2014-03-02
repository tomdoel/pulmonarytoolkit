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
    end
    
    properties (Access = private)
        FloatingPanelYPosition
        Slider
        SliderValueChangedListener
        CachedPanelWidth
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
            obj.AutoAdjustSliderLimits(true);
            
            % Position the slider bar
            obj.Slider.Resize([fixed_panel_size(3) - PTKSlider.SliderWidth + 1, 1, PTKSlider.SliderWidth, fixed_panel_size(4)]);

            % Resize the floating panel. Note this uses the slider position,
            % therefore the slider update should happen first
            obj.UpdateFloatingPanelPosition(true);
        end
        
    end
    
    methods (Access = protected)
        function input_has_been_processed = Scroll(obj, current_point, scroll_count)
            % Called when the mousewheel is used to scroll
            % positive scroll_count = scroll down
            current_value = obj.FloatingPanelYPosition;
            current_value = current_value + 2*scroll_count;
            
            current_value = min(current_value, obj.FloatingPanel.GetRequestedHeight(obj.GetFloatingPanelWidth(false)));
            current_value = max(current_value, 1);
            
            obj.ScrollPanelToThisYPosition(current_value);
            input_has_been_processed = true;
        end
        
        function ScrollPanelToThisYPosition(obj, y_top)
            % Moves the sliding panel so that the location y_top is visible at
            % the top of the panel. y_top is measured from the top of the
            % floating panel in pixels.
            
            % The base of the floating panel never goes beyond the bottom of the
            % fixed panel
            y_top = min(y_top, obj.GetSliderRange);
            
            obj.FloatingPanelYPosition = y_top;
            obj.SetSliderFromFloatingPanelYPosition;
            obj.UpdateFloatingPanelPosition(false);
            
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
            floating_panel_height = obj.FloatingPanel.GetRequestedHeight(obj.GetFloatingPanelWidth(false));
            range = max(0, floating_panel_height - fixed_panel_height);
        end
        
        function SliderValueChanged(obj, ~, ~)
            obj.SetFloatingPanelYPositionFromSlider;
            obj.UpdateFloatingPanelPosition(false);
        end        
        
        
        function UpdateFloatingPanelPosition(obj, force_resize)
            
            fixed_panel_size = obj.Position;
            
            floating_panel_width = obj.GetFloatingPanelWidth(force_resize);
            
            floating_panel_height = obj.FloatingPanel.GetRequestedHeight(floating_panel_width);
            overlap_height = max(0, floating_panel_height - fixed_panel_size(4));
            slider_is_visible = overlap_height > 0;

            if slider_is_visible            
                y_pos = obj.FloatingPanelYPosition - overlap_height;
            else
                y_pos = 1 + fixed_panel_size(4) - floating_panel_height;
            end

            visible_floating_panel_height = fixed_panel_size(4) - y_pos;
            floating_panel_position = [1, y_pos, floating_panel_width, visible_floating_panel_height];
            obj.FloatingPanel.Resize(floating_panel_position);
        end
        
        function panel_width = GetFloatingPanelWidth(obj, force_resize)
            % Returns the width of the floating panel, excluding the slider width if necessary
            
            
            % When resizing, we may need to call GetRequestedHeight() twice on the floating
            % panel with different width values, since the width and height of the floating
            % panel will change if a slider is required. This is costly, since the caching
            % will only store the last value. To prevent this, we cache the last width value
            % and use it unless a resize is required.
            if isempty(obj.CachedPanelWidth) || force_resize
                
                fixed_panel_size = obj.Position;
                floating_panel_width = fixed_panel_size(3);
                floating_panel_height = obj.FloatingPanel.GetRequestedHeight(floating_panel_width);
                overlap_height = max(0, floating_panel_height - fixed_panel_size(4));
                
                % If there is an overlap, the slider will be visible. This means we need to
                % reduce the panel width to account for the slider width
                if overlap_height > 0
                    floating_panel_width = floating_panel_width - PTKSlider.SliderWidth;
                end
                
                obj.CachedPanelWidth = floating_panel_width;
            end
            panel_width = obj.CachedPanelWidth;
        end

        function AutoAdjustSliderLimits(obj, force_resize)
            fixed_panel_size = obj.Position;
            fixed_panel_height = fixed_panel_size(4);
            floating_panel_height = obj.FloatingPanel.GetRequestedHeight(obj.GetFloatingPanelWidth(force_resize));
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