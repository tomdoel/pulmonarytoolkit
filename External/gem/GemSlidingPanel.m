classdef GemSlidingPanel < GemPanel
    % GemSlidingPanel GEM class for a sliding panel, where the panel can
    %     be scrolled vertically.
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = protected)
        FloatingPanel
    end
    
    properties (Access = private)
        FloatingPanelYPosition
        Slider
        CachedPanelWidth
    end
    
    methods
        function obj = GemSlidingPanel(parent_handle)
            obj = obj@GemPanel(parent_handle);
            obj.Slider = GemSlider(obj);
            obj.AddChild(obj.Slider);
            obj.FloatingPanelYPosition = 0;
            obj.AddEventListener(obj.Slider, 'SliderValueChanged', @obj.SliderValueChanged);
        end

        function Resize(obj, fixed_panel_size)
            
            % Resize the fixed panel
            Resize@GemPanel(obj, fixed_panel_size);

            % Position the slider bar
            obj.Slider.Resize([fixed_panel_size(3) - GemSlider.SliderWidth + 1, 1, GemSlider.SliderWidth, fixed_panel_size(4)]);
            
            obj.AutoAdjustSliderLimits(true);
            
            % Resize the floating panel. Note this uses the slider position,
            % therefore the slider update should happen first
            obj.UpdateFloatingPanelPosition(true);
        end
        
        function ScrollToTop(obj)
            obj.ScrollPanelToThisYPosition(0);
        end
        
    end
    
    methods (Access = protected)
        function input_has_been_processed = Scroll(obj, current_point, scroll_count, src, eventdata)
            % Called when the mousewheel is used to scroll
            % positive scroll_count = scroll down
            current_value = obj.FloatingPanelYPosition;
            current_value = current_value + 2*scroll_count;
            
            current_value = min(current_value, obj.FloatingPanel.GetRequestedHeight(obj.GetFloatingPanelWidth(false)));
            current_value = max(current_value, 0);
            
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
        
        function ScrollToShow(obj, y_top, y_bottom)
            % Moves the sliding panel so that all coordinates between y_top and y_bottom are
            % visible
            
            fixed_panel_height = obj.Position(4);
            if y_bottom > (obj.FloatingPanelYPosition + fixed_panel_height)
                obj.ScrollPanelToThisYPosition(y_bottom - fixed_panel_height);
            end
            if y_top < obj.FloatingPanelYPosition
                obj.ScrollPanelToThisYPosition(y_top);
            end
            
            
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

            obj.FloatingPanelYPosition = min(obj.FloatingPanelYPosition, overlap_height);
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
                    floating_panel_width = floating_panel_width - GemSlider.SliderWidth;
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
            new_steps = [min(1, 30/(overlap_height - 0)), min(1, 300/(overlap_height - 0))];
            
            % This is to prevent an error where the slider is invisible but
            % the steps are set nonetheless
            if new_steps(2) <= new_steps(1)
                new_steps(1) = new_steps(2)/10;
            end
            obj.Slider.SetSliderLimits(slider_min, slider_max);
            obj.Slider.SetSliderSteps(new_steps);
            
            obj.SetSliderFromFloatingPanelYPosition;
            
            if overlap_height > 0
                obj.Slider.Enable;
            else
                obj.Slider.Disable;
            end
        end
        
    end
end