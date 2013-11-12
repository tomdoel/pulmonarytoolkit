classdef PTKSlidingPanel < PTKPanel
    % PTKSlidingPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the PUlmonary Toolkit to help
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
        SliderControl
        SliderWidth = 15
    end
    
    methods
        function obj = PTKSlidingPanel(parent_handle, reporting)
            obj = obj@PTKPanel(parent_handle, reporting);

            % Create the sider
            obj.SliderControl = uicontrol('Style', 'slider', 'Parent', obj.PanelHandle, 'TooltipString', 'Scroll through slices', 'Units', 'pixels', 'Value', 0);
            setappdata(obj.ParentHandle ,'sliderListeners', handle.listener(obj.SliderControl, 'ActionEvent', @obj.SliderCallback));            
        end

        function Resize(obj, fixed_panel_size)
            
            % Update the slider to reflect the change in window height
            obj.ChangeSliderLimits(fixed_panel_size(4));
            
            % Position the slider bar
            slider_size = [fixed_panel_size(3) - obj.SliderWidth + 1, 1, obj.SliderWidth, fixed_panel_size(4)];
            set(obj.SliderControl, 'Units', 'pixels', 'Position', slider_size);

            % Resize the floating panel. Note this uses the slider position,
            % therefore the slider update should happen first
            obj.UpdateFloatingPanelPosition(fixed_panel_size);            
            
            % Position the fixed panel
            Resize@PTKPanel(obj, fixed_panel_size);
            
        end
        
        function input_has_been_processed = Scroll(obj, scroll_count, current_point)
            fixed_panel_position = get(obj.PanelHandle, 'Position');
            
            if (current_point(1) >= fixed_panel_position(1) && current_point(2) >= fixed_panel_position(2) && ...
                    current_point(1) <= fixed_panel_position(1) + fixed_panel_position(3) && ...
                    current_point(2) <= fixed_panel_position(2) + fixed_panel_position(4))
                
                % positive scroll_count = scroll down
                current_value = get(obj.SliderControl, 'Value');
                current_value = current_value - 2*scroll_count;
                current_value = min(current_value, get(obj.SliderControl, 'Max'));
                current_value = max(current_value, 1);
                set(obj.SliderControl, 'Value', current_value);
                obj.UpdateSlider;
                input_has_been_processed = true;
            else
                input_has_been_processed = false;
            end
        end
    end
    
    methods (Access = protected)
        function Update(obj)
            obj.UpdateSlider;
        end
        
        function ScrollPanelToThisYPosition(obj, y_top, fixed_panel_position)
            floating_panel_height = obj.FloatingPanel.GetRequestedHeight;
            overlap_height = max(0, floating_panel_height - fixed_panel_position(4));
            
            slider_is_visible = overlap_height > 0;
            
            if slider_is_visible
                y_pos = max(0, overlap_height - y_top);
            else
                y_pos = 1 + fixed_panel_position(4) - floating_panel_height;
            end
            y_pos = max(0, y_pos);
            y_pos = min(overlap_height, y_pos);
            set(obj.SliderControl, 'Value', y_pos);
            obj.UpdateSlider;            
        end
        
    end
    
    methods (Access = private)
        
        
        function UpdateSlider(obj)
            % Get current panel width
            fixed_panel_size = get(obj.PanelHandle, 'Position');
            
            obj.UpdateFloatingPanelPosition(fixed_panel_size);            
        end
        
        function UpdateFloatingPanelPosition(obj, fixed_panel_size)
            
            floating_panel_height = obj.FloatingPanel.GetRequestedHeight;            
            overlap_height = max(0, floating_panel_height - fixed_panel_size(4));
            slider_is_visible = overlap_height > 0;
            
            floating_panel_width = fixed_panel_size(3);
            if slider_is_visible
                floating_panel_width = floating_panel_width - obj.SliderWidth;
                y_offset = round(get(obj.SliderControl, 'Value'));
                y_pos = 1  - y_offset;
            else
                y_pos = 1 + fixed_panel_size(4) - floating_panel_height;
            end
                        
            floating_panel_position = [1, y_pos, floating_panel_width, floating_panel_height];
            obj.FloatingPanel.Resize(floating_panel_position);
        end
                               
        function SliderCallback(obj, hObject, ~)
            obj.UpdateSlider;
        end
        
        
        function ChangeSliderLimits(obj, fixed_panel_height)
            
            floating_panel_height = obj.FloatingPanel.GetRequestedHeight;
            
            overlap_height = max(0, floating_panel_height - fixed_panel_height);
            
            is_visible = strcmp('on', get(obj.SliderControl, 'Visible'));
            
            if (overlap_height > 0)
                
                % We want to keep the panel floating panel top-aligned with its
                % parent panel when we re-size. However, this requires us to
                % modify the slider value, since the slider limits may change as
                % we resize. Initially, we want the floating panel top-aligned,
                % corresponding to a maximum slider value.
                old_value = get(obj.SliderControl, 'Value');
                old_max = get(obj.SliderControl, 'Max');
                new_max = overlap_height;
                new_value = old_value + new_max - old_max;
                new_value = max(0, new_value);
                new_value = min(overlap_height, new_value);
                
                set(obj.SliderControl, 'Min', 0);
                set(obj.SliderControl, 'Max', new_max);
                
                set(obj.SliderControl, 'Value', new_value);
                set(obj.SliderControl, 'SliderStep', [min(1, 30/(overlap_height - 0)), 300/(overlap_height - 0)]);
                
                if ~is_visible
                    set(obj.SliderControl, 'Visible', 'on');
                end
            else
                if is_visible
                    set(obj.SliderControl, 'Visible', 'off');
                end
            end            
        end
        
    end
end