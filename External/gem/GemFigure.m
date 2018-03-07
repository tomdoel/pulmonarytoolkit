classdef GemFigure < GemUserInterfaceObject
    % GemFigure GEM class for a Matlab figure
    %
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        Title
    end
    
    properties (Access = protected)
        ArrowPointer
        DefaultKeyHandlingObject % If a keypress is not handled by any objects, then the default object may handle it
    end
    
    properties (Access = private)
        CachedTitle
        OldResizeFunction;
        OldWindowScrollWheelFunction
        MouseCapturingObject % This is the GemUserInterfaceObject which has captured the mouse input after a mouse down
        MouseOverObject % This is the GemUserInterfaceObject which last processed a MouseHasMoved event
        LastCursor
        IsDraggingMarkerPoint = false
    end

    methods
        function obj = GemFigure(title, position, reporting)
            obj = obj@GemUserInterfaceObject([], reporting);
            obj.Title = title;
            obj.ArrowPointer = 'arrow';
            
            % Set the initial position. If this is not set, you must call
            % Resize() to set a position before making the figure visible
            if ~isempty(position)
                obj.Resize(position);
            end
        end

        function delete(obj)
            if ishandle(obj.GraphicalComponentHandle)
                % Remove custom handlers
                obj.DisableMatlabHandleListeners;
                set(obj.GraphicalComponentHandle, 'ResizeFcn', @obj.OldResizeFunction);
                set(obj.GraphicalComponentHandle, 'WindowScrollWheelFcn', @obj.OldWindowScrollWheelFunction);
            end
        end
        
        function set.Title(obj, title)
            obj.Title = title;
            if ishandle(obj.GraphicalComponentHandle)
                set(obj.GraphicalComponentHandle, 'Name', title);
            end
        end
        
        function BringToFront(obj)
            if obj.ComponentHasBeenCreated
                figure(obj.GraphicalComponentHandle);
            end
        end
        
        function CreateGuiComponent(obj, position)
            
            % The busy action can be set to 'cancel' (ignore callbacks which come in while
            % this one is being processed) or 'queue' (queue up all callbacks)
            obj.GraphicalComponentHandle = figure('Color', obj.StyleSheet.BackgroundColour, 'Visible', 'off', ...
                'numbertitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
                'Units', 'pixels', 'Position', position, 'Name', obj.Title, 'Pointer', obj.ArrowPointer, ...
                'Interruptible', 'off', 'BusyAction', 'queue');
            
            % Store old custom handlers for this figure
            obj.OldWindowScrollWheelFunction = get(obj.GraphicalComponentHandle, 'WindowScrollWheelFcn');
            obj.OldResizeFunction = get(obj.GraphicalComponentHandle, 'ResizeFcn');

            % Set custom handlers
            set(obj.GraphicalComponentHandle, 'CloseRequestFcn', @obj.CustomCloseFunction);
            set(obj.GraphicalComponentHandle, 'ResizeFcn', @obj.CustomResize);
            
            % Add custom keyboard handlers
            obj.RestoreCustomKeyPressCallback;
        end
        
        function CustomKeyPressedFunction(obj, src, eventdata)
            current_point = get(obj.GraphicalComponentHandle, 'CurrentPoint') + obj.Position(1:2) - 1;
            processing_object = obj.ProcessActivity('Keypressed', current_point, eventdata.Key);
            if isempty(processing_object) && ~isempty(obj.DefaultKeyHandlingObject)
                obj.ProcessActivityToSpecificObject(obj.DefaultKeyHandlingObject, 'Keypressed', current_point, eventdata.Key, src, eventdata);
            end
        end
        
        function CustomWindowButtonDownFunction(obj, src, eventdata)
            obj.IsDraggingMarkerPoint = false;
            
            % Called when mouse button is pressed
            selection_type = get(src, 'SelectionType');
            
            % The object which processed the MouseDown will capture mouse input until a
            % MouseUp event
            obj.MouseCapturingObject = obj.ProcessActivity('MouseDown', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, selection_type, src, eventdata);
        end
        
        function CustomWindowButtonUpFunction(obj, src, eventdata)
            % Called when mouse button is released
            
            if ~obj.IsDraggingMarkerPoint
                % MouseUp events are always sent to the object which originally received the
                % MouseDown, regardless of where the cursor is now
                selection_type = get(src, 'SelectionType');
                if ~isempty(obj.MouseCapturingObject) && isvalid(obj.MouseCapturingObject)
                    obj.ProcessActivityToSpecificObject(obj.MouseCapturingObject, 'MouseUp', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, selection_type, src, eventdata);
                end
                
                obj.MouseCapturingObject = [];
            end
        end
        
        function CustomWindowButtonMotionFunction(obj, src, eventdata)
            % Called when mouse is moved
            
            if isvalid(obj)
                % If the mouse button is currently down, the mouse move is processed by the
                % object which received the MouseDown event, regardless of where the mouse
                % cursor currently is. Otherwise, the mouse move event goes to the object under
                % the cursor
                selection_type = get(src, 'SelectionType');
                if isempty(obj.MouseCapturingObject) || ~isvalid(obj.MouseCapturingObject)
                    mouse_over_object = obj.ProcessActivity('MouseHasMoved', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, selection_type, src, eventdata);
                    if ~isempty(obj.MouseOverObject) && isvalid(obj.MouseOverObject) && (isempty(mouse_over_object) || (mouse_over_object ~= obj.MouseOverObject))
                        obj.ProcessActivityToSpecificObject(obj.MouseOverObject, 'MouseExit', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, selection_type, src, eventdata);
                    end
                    obj.MouseOverObject = mouse_over_object;
                else
                    obj.ProcessActivityToSpecificObject(obj.MouseCapturingObject, 'MouseDragged', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, selection_type, src, eventdata);
                end
            end
        end

        function CustomWindowScrollWheelFunction(obj, src, eventdata)
            scroll_count = eventdata.VerticalScrollCount; % positive = scroll down
            obj.ProcessActivity('Scroll', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, scroll_count, src, eventdata);
        end
        
        function ShowWaitCursor(obj)
            % Changes the mouse cursor to a wait cursor
            if isempty(obj.LastCursor)
                obj.LastCursor = get(obj.GraphicalComponentHandle, 'Pointer');
            end
            
            set(obj.GraphicalComponentHandle, 'Pointer', 'watch');
            drawnow;

        end
        
        function HideWaitCursor(obj)
            % Restores the mouse cursor to the previous cursor
            set(obj.GraphicalComponentHandle, 'Pointer', obj.LastCursor);
            obj.LastCursor = [];
            drawnow;
        end
        
        function id = RegisterMarkerPoint(obj, point_handle)
            id = point_handle.addNewPositionCallback(@obj.MarkerPositionChangedCallback);
        end
        
        function UnRegisterMarkerPoint(obj, point_handle, id)
            point_handle.removeNewPositionCallback(id);
        end
        
        function callback = GetWindowButtonDownFunction(obj)
            callback = @obj.CustomWindowButtonDownFunction;
        end
    end

    methods (Access = protected)
        
        function CustomResize(obj, eventdata, handles)
            obj.ObjectHasBeenResized;
            
            if (~isempty(obj.OldResizeFunction))
                obj.OldResizeFunction(eventdata, handles);
            end
        end

        function CustomCloseFunction(obj, ~, ~)
            % Our default figure behaviour is to destroy the object and its
            % controls on close
            delete(obj);
        end

        function MarkerPositionChangedCallback(obj, new_position)
            obj.IsDraggingMarkerPoint = true;
        end        
    end
end