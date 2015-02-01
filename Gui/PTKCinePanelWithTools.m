classdef PTKCinePanelWithTools < PTKCinePanel
    % PTKCinePanelWithTools.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = protected)
        ViewerPanel
        
        % Used for programmatic pan, zoom, etc.
        LastCoordinates = [0, 0, 0]
        MouseIsDown = false
        ToolOnMouseDown
        LastCursor
        CurrentCursor = ''
    end
    
    events
        MousePositionChanged
    end

    methods
        function obj = PTKCinePanelWithTools(parent, viewer_panel, reporting)
            image_source = PTKImageVolumeSource(viewer_panel);
            
            image_overlay_axes = PTKImageOverlayAxes(parent, image_source, viewer_panel, reporting);
            
            obj = obj@PTKCinePanel(parent, image_source, image_overlay_axes, reporting);
            obj.ViewerPanel = viewer_panel;
        end

        function UpdateCursor(obj, hObject, mouse_is_down, keyboard_modifier)
            global_coords = obj.GetImageCoordinates;
            point_is_in_image = obj.ImageSource.IsPointInImage(global_coords);
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
                orientation = obj.ImageSource.GetOrientation;
                i_screen = coords(2,1);
                j_screen = coords(2,2);
                k_screen = obj.ImageSource.GetSliceNumberForOrientation(orientation);
                
                switch orientation
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
        
        function DrawImages(obj, update_background, update_overlay, update_quiver)
            if update_background
                obj.Axes.DrawBackgroundImage;
            end
            if update_overlay
                obj.Axes.DrawOverlayImage;
            end
            if update_quiver
                obj.Axes.DrawQuiverImage;
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
            if (obj.ImageSource.IsPointInImage(global_coords))
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
                if (obj.ImageSource.IsPointInImage(global_coords))
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
            tool.MouseHasMoved(screen_coords, last_coords);
            
            obj.UpdateCursor(src, false, selection_type);
            obj.UpdateStatus(true);
            input_has_been_processed = true;
        end
        
        function input_has_been_processed = MouseDragged(obj, click_point, selection_type, src)
            % Mouse dragged over the figure

            screen_coords = obj.GetScreenCoordinates;
            last_coords = obj.LastCoordinates;
            
            tool = obj.GetCurrentTool(true, selection_type);
            tool.MouseDragged(screen_coords, last_coords);
            
            obj.UpdateCursor(src, true, selection_type);
            obj.UpdateStatus(true);
            input_has_been_processed = true;
        end
 
        function input_has_been_processed = MouseExit(obj, click_point, selection_type, src)
            % This method is called when the mouse exits a control which previously
            % processed a MouseHasMoved event
            
            obj.UpdateStatus(false);
            input_has_been_processed = false;
        end
        
        function UpdateStatus(obj, in_image)
            image_coordinates = obj.GetImageCoordinates;
            notify(obj, 'MousePositionChanged', PTKEventData(PTKCoordsInImage(image_coordinates, in_image)));
        end
        
        function SliderValueChanged(obj, ~, ~)
            obj.ImageSource.SetSliceNumberForOrientation(obj.ImageSource.GetOrientation, round(obj.Slider.SliderValue));
        end
        
    end
end