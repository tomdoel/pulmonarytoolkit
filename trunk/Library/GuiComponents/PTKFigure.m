classdef PTKFigure < PTKUserInterfaceObject
    % PTKFigure. Gui for choosing a dataset to view
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
        MouseCapturingObject % This is the PTKUserInterfaceObject which has captured the mouse input after a mouse down
        MouseOverObject % This is the PTKUserInterfaceObject which last processed a MouseHasMoved event
        LastCursor
    end

    methods
        function obj = PTKFigure(title, position)
            obj = obj@PTKUserInterfaceObject([]);
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
        
        function CreateGuiComponent(obj, position, reporting)
            
            % The busy action can be set to 'cancel' (ignore callbacks which come in while
            % this one is being processed) or 'queue' (queue up all callbacks)
            obj.GraphicalComponentHandle = figure('Color', PTKSoftwareInfo.BackgroundColour, 'Visible', 'off', ...
                'numbertitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
                'Units', 'pixels', 'Position', position, 'Name', obj.Title, 'Pointer', obj.ArrowPointer, ...
                'Interruptible', 'off', 'BusyAction', 'queue');
            
            % Store old custom handlers for this figure
            obj.OldWindowScrollWheelFunction = get(obj.GraphicalComponentHandle, 'WindowScrollWheelFcn');
            obj.OldResizeFunction = get(obj.GraphicalComponentHandle, 'ResizeFcn');
            
            % Set custom handlers
            set(obj.GraphicalComponentHandle, 'CloseRequestFcn', @obj.CustomCloseFunction);
            set(obj.GraphicalComponentHandle, 'WindowScrollWheelFcn', @obj.CustomWindowScrollWheelFunction);
            set(obj.GraphicalComponentHandle, 'WindowButtonDownFcn', @obj.CustomWindowButtonDownFunction);
            set(obj.GraphicalComponentHandle, 'WindowButtonUpFcn', @obj.CustomWindowButtonUpFunction);            
            set(obj.GraphicalComponentHandle, 'WindowButtonMotionFcn', @obj.CustomWindowButtonMotionFunction);
            set(obj.GraphicalComponentHandle, 'KeyPressFcn', @obj.CustomKeyPressedFunction);
            set(obj.GraphicalComponentHandle, 'ResizeFcn', @obj.CustomResize);
        end
        
        function RestoreCustomKeyPressCallback(obj)
            % For the zoom and pan tools, we need to disable the Matlab fuctions
            % that prevent custom keyboard callbacks being used; otherwise our
            % keyboard shortcuts will be sent to the command line
            
            hManager = uigetmodemanager(obj.GraphicalComponentHandle);
            
            
            %%%% Todo: Disabled due to incompatibality with hg2 in Matlab 8.4
%             set(hManager.WindowListenerHandles, 'Enable', 'off');
        end
        
        function CustomKeyPressedFunction(obj, src, eventdata)
            current_point = get(obj.GraphicalComponentHandle, 'CurrentPoint') + obj.Position(1:2) - 1;
            processing_object = obj.ProcessActivity('Keypressed', current_point, eventdata.Key);
            if isempty(processing_object) && ~isempty(obj.DefaultKeyHandlingObject)
                obj.ProcessActivityToSpecificObject(obj.DefaultKeyHandlingObject, 'Keypressed', current_point, eventdata.Key);
            end
        end
        
        function ShowWaitCursor(obj)
            if isempty(obj.LastCursor)
                obj.LastCursor = get(obj.GraphicalComponentHandle, 'Pointer');
            end
            
            set(obj.GraphicalComponentHandle, 'Pointer', 'watch');
            drawnow;

        end
        
        function HideWaitCursor(obj)
            set(obj.GraphicalComponentHandle, 'Pointer', obj.LastCursor);
            obj.LastCursor = [];
            drawnow;
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

        function CustomWindowButtonDownFunction(obj, src, eventdata)
            % Called when mouse button is pressed
            selection_type = get(src, 'SelectionType');
            
            % The object which processed the MouseDown will capture mouse input until a
            % MouseUp event
            obj.MouseCapturingObject = obj.ProcessActivity('MouseDown', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, selection_type, src);
        end
        
        function CustomWindowButtonUpFunction(obj, src, eventdata)
            % Called when mouse button is released
            
            % MouseUp events are always sent to the object which originally received the
            % MouseDown, regardless of where the cursor is now
            selection_type = get(src, 'SelectionType');
            if ~isempty(obj.MouseCapturingObject) && isvalid(obj.MouseCapturingObject)
                obj.ProcessActivityToSpecificObject(obj.MouseCapturingObject, 'MouseUp', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, selection_type, src);
            end
            
            obj.MouseCapturingObject = [];
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
                    mouse_over_object = obj.ProcessActivity('MouseHasMoved', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, selection_type, src);
                    if ~isempty(obj.MouseOverObject) && isvalid(obj.MouseOverObject) && (isempty(mouse_over_object) || (mouse_over_object ~= obj.MouseOverObject))
                        obj.ProcessActivityToSpecificObject(obj.MouseOverObject, 'MouseExit', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, selection_type, src);
                    end
                    obj.MouseOverObject = mouse_over_object;
                else
                    obj.ProcessActivityToSpecificObject(obj.MouseCapturingObject, 'MouseDragged', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, selection_type, src);
                end
            end
        end

        function CustomWindowScrollWheelFunction(obj, src, eventdata)
            scroll_count = eventdata.VerticalScrollCount; % positive = scroll down
            obj.ProcessActivity('Scroll', get(src, 'CurrentPoint') + obj.Position(1:2) - 1, scroll_count);
        end
    end
end