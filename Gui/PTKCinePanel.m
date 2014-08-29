classdef PTKCinePanel < PTKVirtualPanel
    % PTKCinePanel.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKCinePanel contains a 2D image and a slider, which allows the user to
    %     cine through slices of a 3D images
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        Axes
        ControlPanel
        Slider
        ViewerPanel
        
        % Used for programmatic pan, zoom, etc.
        LastCoordinates = [0, 0, 0]
        MouseIsDown = false
        ToolOnMouseDown
        LastCursor
        CurrentCursor = ''
    end
    
    methods
        function obj = PTKCinePanel(viewer_panel, control_panel, reporting)
            obj = obj@PTKVirtualPanel(viewer_panel, reporting);
            obj.ViewerPanel = viewer_panel;
            obj.ControlPanel = control_panel;

            obj.Slider = PTKSlider(obj);
            obj.AddChild(obj.Slider, obj.Reporting);
            
            obj.Axes = PTKImageOverlayAxes(obj.ViewerPanel, reporting);
            obj.AddChild(obj.Axes, obj.Reporting);
            
            obj.AddEventListener(obj.Slider, 'SliderValueChanged', @obj.SliderValueChanged);            
        end

        function Resize(obj, position)
            Resize@PTKUserInterfaceObject(obj, position);
            
            % Resize axes
            axis_width = max(1, position(3) - obj.Slider.SliderWidth);
            axes_position = [1, position(2), axis_width, position(4)];
            obj.Axes.Resize(axes_position);
            
            % Resize slider
            slider_x = position(1) + axis_width;
            slider_position = [slider_x, position(2), obj.Slider.SliderWidth, position(4)];
            obj.Slider.Resize(slider_position);            
        end
        
        function SetSliceNumber(obj, slice_number)
            current_slice_value = obj.Slider.SliderValue;
            if (current_slice_value ~= slice_number)
                obj.Slider.SetSliderValue(slice_number);
            end
        end
        
        function SetSliderLimits(obj, min, max)
            obj.Slider.SetSliderLimits(min, max);
        end
        
        function SetSliderSteps(obj, steps)
            obj.Slider.SetSliderSteps(steps);
        end
  
        function SliderValueChanged(obj, ~, ~)
            obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation) = round(obj.Slider.SliderValue);
        end
        
        function frame = Capture(obj)
            drawnow;
            
            origin = [0.5, 0.5, 0.5];
            image_limit = origin + obj.ViewerPanel.BackgroundImage.ImageSize;
            switch obj.ViewerPanel.Orientation
                case PTKImageOrientation.Coronal
                    xlim_image = [origin(2), image_limit(2)];
                    ylim_image = [origin(3), image_limit(3)];
                case PTKImageOrientation.Sagittal
                    xlim_image = [origin(1), image_limit(1)];
                    ylim_image = [origin(3), image_limit(3)];
                case PTKImageOrientation.Axial
                    xlim_image = [origin(2), image_limit(2)];
                    ylim_image = [origin(1), image_limit(1)];
            end

            frame = obj.Axes.Capture(xlim_image, ylim_image);
        end

        function ZoomTo(obj, i_limits, j_limits, k_limits)
            % Changes the current axis limits to the specified global coordinates
            % i_limits = [minimum_i, maximum_i] and the same for j, k.
                        
            % Convert global coordinates to local coordinates
            origin = obj.ViewerPanel.BackgroundImage.Origin;
            i_limits_local = i_limits - origin(1) + 1;
            j_limits_local = j_limits - origin(2) + 1;
            k_limits_local = k_limits - origin(3) + 1;
            
            obj.Axes.ZoomTo(obj, obj.ViewerPanel.Orientation, i_limits_local, j_limits_local, k_limits_local);
            
            % Update the currently displayed slice to be the centre of the
            % requested box
            obj.ViewerPanel.SliceNumber = [round((i_limits_local(2)+i_limits_local(1))/2), round((j_limits_local(2)+j_limits_local(1))/2), round((k_limits_local(2)+k_limits_local(1))/2)];
        end
        
        function ClearAxesCache(obj)
            obj.Axes.ClearAxesCache;
        end
            
        function UpdateAxes(obj)
            obj.Axes.UpdateAxesAndScreenImages(obj.ViewerPanel.BackgroundImage, obj.ViewerPanel.OverlayImage, obj.ViewerPanel.QuiverImage, obj.ViewerPanel.Orientation);
        end
        
        function DrawImages(obj, update_background, update_overlay, update_quiver)
            if update_background
                obj.Axes.DrawBackgroundImage(obj.ViewerPanel);
            end
            if update_overlay
                obj.Axes.DrawOverlayImage(obj.ViewerPanel);
            end
            if update_quiver
                obj.Axes.DrawQuiverImage(obj.ViewerPanel.ShowOverlay, obj.ViewerPanel);
            end
        end
        
        function screen_coords = GetScreenCoordinates(obj)
            coords = obj.Axes.GetCurrentPoint;
            if (~isempty(coords))
                i_screen = coords(2,1);
                j_screen = coords(2,2);
                screen_coords = [i_screen, j_screen];
            else
                screen_coords = [0, 0];
            end
        end
        
        function current_point = GetCurrentPoint(obj)
            current_point = obj.Axes.GetCurrentPoint;
        end
       
        function axes_object = GetAxes(obj)
            if isempty(obj.Axes)
                obj.Reporting.Error('PTKCinePanel:AxesDoNotExist', 'Axes have not been created');
            end
            axes_object = obj.Axes;
        end
       
        function UpdateCursor(obj, hObject, mouse_is_down, keyboard_modifier)
            global_coords = obj.GetImageCoordinates;
            point_is_in_image = obj.ViewerPanel.BackgroundImage.IsPointInImage(global_coords);
            if (~point_is_in_image)
                obj.MouseIsDown = false;
            end
            
            if point_is_in_image
                current_tool = obj.GetCurrentTool(mouse_is_down, keyboard_modifier);
                new_cursor = current_tool.Cursor;
            else
                new_cursor = 'arrow';
            end
            
            if ~strcmp(obj.CurrentCursor, new_cursor)
                set(hObject, 'Pointer', new_cursor);
                obj.CurrentCursor = new_cursor;
            end
            
        end
        
        function global_coords = GetImageCoordinates(obj)
            coords = round(obj.GetCurrentPoint);
            if (~isempty(coords))
                i_screen = coords(2,1);
                j_screen = coords(2,2);
                k_screen = obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation);
                
                switch obj.ViewerPanel.Orientation
                    case PTKImageOrientation.Coronal
                        i = k_screen;
                        j = i_screen;
                        k = j_screen;
                    case PTKImageOrientation.Sagittal
                        i = i_screen;
                        j = k_screen;
                        k = j_screen;
                    case PTKImageOrientation.Axial
                        i = j_screen;
                        j = i_screen;
                        k = k_screen;
                end
            else
                i = 1;
                j = 1;
                k = 1;
            end
            global_coords = obj.ViewerPanel.BackgroundImage.LocalToGlobalCoordinates([i, j, k]);
        end
       
        function UpdateStatus(obj)
            global_coords = obj.GetImageCoordinates;
            if ~isempty(obj.ControlPanel)
                obj.ControlPanel.UpdateStatus(global_coords);
            end
        end
        
    end
    
    methods (Access = protected)
        
        function tool = GetCurrentTool(obj, mouse_is_down, keyboard_modifier)
            % Returns the tool whch is currently selected. If keyboard_modifier is
            % specified, then this may override the current tool
            
            tool = obj.ViewerPanel.GetCurrentTool(mouse_is_down, keyboard_modifier);
        end
        
        function input_has_been_processed = MouseDown(obj, click_point, selection_type, src)
            % This method is called when the mouse is clicked inside the control
            
            screen_coords = obj.GetScreenCoordinates;
            obj.LastCoordinates = screen_coords;
            obj.MouseIsDown = true;
            tool = obj.GetCurrentTool(true, selection_type);
            global_coords = obj.GetImageCoordinates;
            if (obj.ViewerPanel.BackgroundImage.IsPointInImage(global_coords))
                tool.MouseDown(screen_coords);
                obj.ToolOnMouseDown = tool;
                input_has_been_processed = true;
            else
                obj.ToolOnMouseDown = [];
                input_has_been_processed = false;
            end

            obj.UpdateCursor(src, true, selection_type);
            
        end

        function input_has_been_processed = MouseUp(obj, click_point, selection_type, src)
            % This method is called when the mouse is released inside the control
            
            input_has_been_processed = true;
            obj.MouseIsDown = false;

            screen_coords = obj.GetScreenCoordinates;
            obj.LastCoordinates = screen_coords;


            tool = obj.ToolOnMouseDown;
            if ~isempty(tool)
                global_coords = obj.GetImageCoordinates;
                if (obj.ViewerPanel.BackgroundImage.IsPointInImage(global_coords))
                    tool.MouseUp(screen_coords);
                    obj.ToolOnMouseDown = [];
                end
            end
            obj.UpdateCursor(src, false, selection_type);
            
        end
        
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src)
            % Mouse has moved over the figure

            screen_coords = obj.GetScreenCoordinates;
            last_coords = obj.LastCoordinates;
            
            tool = obj.GetCurrentTool(false, selection_type);
            tool.MouseHasMoved(obj, screen_coords, last_coords);
            
            obj.UpdateCursor(src, false, selection_type);
            obj.UpdateStatus;
            input_has_been_processed = true;
        end
        
        function input_has_been_processed = MouseDragged(obj, click_point, selection_type, src)
            % Mouse dragged over the figure

            screen_coords = obj.GetScreenCoordinates;
            last_coords = obj.LastCoordinates;
            
            tool = obj.GetCurrentTool(true, selection_type);
            tool.MouseDragged(obj.ViewerPanel, screen_coords, last_coords);
            
            obj.UpdateCursor(src, true, selection_type);
            obj.UpdateStatus;
            input_has_been_processed = true;
        end
 
    end
    
end