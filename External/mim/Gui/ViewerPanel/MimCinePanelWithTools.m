classdef MimCinePanelWithTools < GemCinePanel
    % MimCinePanelWithTools.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = protected)
        % Used for programmatic pan, zoom, etc.
        LastCoordinates = [0, 0, 0]
        MouseIsDown = false
        ToolOnMouseDown
        LastCursor
        CurrentCursor = ''
        Tools
    end
    
    methods
        function obj = MimCinePanelWithTools(parent, tools, image_overlay_axes, background_image_source, image_parameters)
            obj = obj@GemCinePanel(parent, background_image_source, image_parameters, image_overlay_axes);
            obj.Tools = tools;
        end

        function UpdateCursor(obj, hObject, mouse_is_down, keyboard_modifier)
            global_coords = obj.GetImageCoordinates;
            point_is_in_image = obj.ImageSource.Image.IsPointInImage(global_coords);
            if (~point_is_in_image)
                obj.MouseIsDown = false;
            end
            
            if point_is_in_image
                current_tool = obj.GetCurrentTool(mouse_is_down, keyboard_modifier);
                new_cursor = current_tool.GetCursor();
            else
                new_cursor = 'arrow';
            end
            
            if ~strcmp(obj.CurrentCursor, new_cursor)
                if ischar(new_cursor)
                    set(hObject, 'Pointer', new_cursor);
                else
                    set(hObject, 'Pointer', 'Custom');
                    set(hObject, 'PointerShapeCData', new_cursor);
                end
                obj.CurrentCursor = new_cursor;
            end
            
        end        
    end
    
    methods (Access = protected)
        
        function tool = GetCurrentTool(obj, mouse_is_down, keyboard_modifier)
            % Returns the tool whch is currently selected. If keyboard_modifier is
            % specified, then this may override the current tool
            
            tool = obj.Tools.GetCurrentToolForSelectedControl(mouse_is_down, keyboard_modifier);
        end
        
        function input_has_been_processed = MouseDown(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is clicked inside the control
            
            MouseDown@GemCinePanel(obj, click_point, selection_type, src, eventdata);
            screen_coords = obj.GetScreenCoordinates;
            obj.LastCoordinates = screen_coords;
            obj.MouseIsDown = true;
            tool = obj.GetCurrentTool(true, selection_type);
            global_coords = obj.GetImageCoordinates;
            if (obj.ImageSource.Image.IsPointInImage(global_coords))
                tool.MouseDown(screen_coords);
                obj.ToolOnMouseDown = tool;
                input_has_been_processed = true;
            else
                obj.ToolOnMouseDown = [];
                input_has_been_processed = false;
            end

            obj.UpdateCursor(src, true, selection_type);
            
        end

        function input_has_been_processed = MouseUp(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is released inside the control
            
            MouseUp@GemCinePanel(obj, click_point, selection_type, src, eventdata);
            input_has_been_processed = true;
            obj.MouseIsDown = false;

            screen_coords = obj.GetScreenCoordinates;
            obj.LastCoordinates = screen_coords;

            tool = obj.ToolOnMouseDown;
            if ~isempty(tool)
                global_coords = obj.GetImageCoordinates;
                if (obj.ImageSource.Image.IsPointInImage(global_coords))
                    tool.MouseUp(screen_coords);
                    obj.ToolOnMouseDown = [];
                end
            end
            obj.UpdateCursor(src, false, selection_type);
            
        end
        
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src, eventdata)
            % Mouse has moved over the figure

            MouseHasMoved@GemCinePanel(obj, click_point, selection_type, src);
            screen_coords = obj.GetScreenCoordinates;
            last_coords = obj.LastCoordinates;

            tool = obj.GetCurrentTool(false, selection_type);
            tool.MouseHasMoved(screen_coords, last_coords);

            obj.UpdateCursor(src, false, selection_type);
            input_has_been_processed = true;
        end
        
        function input_has_been_processed = MouseDragged(obj, click_point, selection_type, src, eventdata)
            % Mouse dragged over the figure

            MouseDragged@GemCinePanel(obj, click_point, selection_type, src, eventdata);
            screen_coords = obj.GetScreenCoordinates;
            last_coords = obj.LastCoordinates;
            
            tool = obj.GetCurrentTool(true, selection_type);
            tool.MouseDragged(screen_coords, last_coords);
            
            obj.UpdateCursor(src, true, selection_type);
            input_has_been_processed = true;
        end
 
        function input_has_been_processed = MouseExit(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse exits a control which previously
            % processed a MouseHasMoved event

            MouseExit@GemCinePanel(obj, click_point, selection_type, src);
            
            new_cursor = 'arrow';
            if ~strcmp(obj.CurrentCursor, new_cursor)
                set(src, 'Pointer', new_cursor);
                obj.CurrentCursor = new_cursor;
            end
            
            input_has_been_processed = true;
            
        end
    end
end