classdef GemUserInterfaceObject < CoreBaseClass
    % GemUserInterfaceObject. Base class for GEM user interface components
    %
    % All GEM controls inherit from this class
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    %

    properties
        StyleSheet
    end
    
    properties (SetAccess = protected)
        Parent
        Children
        ParentWindowVisible
        ParentWindowEnabled
        Enabled
        Position
        GraphicalComponentHandle % Handle to the uicontrol/uipanel object (if there is one)
        ComponentHasBeenCreated
        LockResize     % Flag prevents user control from being resized
        ResizeRequired % Flag indicates that a Resize() needs to be called before child controls can be created
        
        LastHandlePosition % Stores the last position set to the handle of the graphics component
        LastHandleVisible  % Stores the last visibility state set to the handle of the graphics component
        
        VisibleParameter = 'on' % Defines the argument for component visibility
    end
    
    properties (Access = protected)        
        Reporting
        
        % Matlab callbacks
        WindowButtonDownFcn
        WindowButtonUpFcn
        WindowButtonMotionFcn
        WindowScrollWheelFcn
        KeyPressFcn
    end
    
    methods (Abstract)
        CreateGuiComponent(obj, position)
    end
    
    methods
        function obj = GemUserInterfaceObject(parent, reporting)

            % Set the parent visibility to the default values for a
            % parentless window. These will be changed when the object is
            % added to its parent via the AddChild() method
            obj.ParentWindowVisible = false;
            obj.ParentWindowEnabled = true;
            
            if nargin < 1 || isempty(parent)
                obj.StyleSheet = GemStyleSheet;
                if nargin < 2 || isempty(reporting)
                    obj.Reporting = CoreReportingDefault;
                else
                    obj.Reporting = reporting;
                end
            else
                obj.StyleSheet = parent.StyleSheet;
                obj.Reporting = parent.Reporting;
            end
            obj.Enabled = true;
            obj.ComponentHasBeenCreated = false;
            obj.Children = [];
            obj.ResizeRequired = false;
            obj.LockResize = false;            
        end
        
        function delete(obj)
            obj.RemoveAndDeleteChildren
            obj.DeleteIfGraphicsHandle(obj.GraphicalComponentHandle);
        end
        
        function AddChild(obj, child)
            % Add a child object to this object. After creating a GemUserInterfaceObject,
            % you must call this method on the parent object in order to add the new object.
            
            if ~isa(child, 'GemUserInterfaceObject')
                obj.Reporting.Error('GemUserInterfaceObject:ChildNotAGemUserInterfaceObject', 'This child obect passed to AddChild is not of type GemUserInterfaceObject');
            end
            
            % Set the parent object in the child
            child.SetParent(obj);
            
            obj.Children{end + 1} = child;
            obj.ResizeRequired = true;
            
            if obj.ComponentHasBeenCreated && obj.IsVisible
                child.Show;
            end
        end
        
        function RemoveAndDeleteChildren(obj)
            % Remove and delete all child graphic objects

            for child = obj.Children
                CoreSystemUtilities.DeleteIfValidObject(child{1});
            end
            obj.Children = [];
        end
        
        function Resize(obj, new_position)
            % Call to change the positon and size of the object.
            % Resize can be called even if the actual underlying graphical object hasn't
            % been created yet - the new position will be cached and applied when it is
            % created.
            % You would normally override this method for any figures and panels you create,
            % in order to provide your desired layout management.
            % When you override this method, you should call this base class.
            
            obj.ResizeRequired = false;
            new_position(3) = max(1, new_position(3));
            new_position(4) = max(1, new_position(4));
            if ~isempty(obj.GraphicalComponentHandle) && obj.IsVisible && ~obj.LockResize
                set(obj.GraphicalComponentHandle, 'Position', new_position);
                obj.LastHandlePosition = new_position;
            end
            obj.Position = new_position;
        end
        
        function ObjectHasBeenResized(obj)
            % This function is called when the underlying graphics object has been resized.
            % Most commonly, this will happen when a figure is resized by the user.
            % We want to ensure all the child objects are correctly resized, so Resize() is
            % called, but we don't want to modify the position of this particular object (as
            % that would trigger a recursive resize call), so we set the LockResize flag to
            % protect this particular control from resize.
            
            new_position = get(obj.GraphicalComponentHandle, 'Position');
            
            % Updage the last known position of the control, since the control has been
            % modified externally
            obj.LastHandlePosition = new_position;
            
            % Lock resize to prevent this control from being modified
            obj.LockResize = true;
            
            % Call Resize (which will typically be overridden by the subclass)
            obj.Resize(new_position);
            
            % Release the lock
            obj.LockResize = false;            
        end
        
        
        function height = GetRequestedHeight(obj, width)
            % Returns a value for the height of the object. A null value indicates
            % the caller can choose the height
            height = [];
        end
        
        
        function Enable(obj)
            % Enables this component
            
            if ~obj.Enabled
                obj.Enabled = true;
                
                % Set the flag determining inherited enabled-ness for this window and all children
                obj.SetAllParentEnabled(obj.ParentWindowEnabled);
                
                % If the component has never been displayed, it may not have a position
                if obj.IsVisible
                    if isempty(obj.Position) && ~isempty(obj.Parent)
                        obj.Parent.Resize(obj.Parent.Position);
                    end
                end
                
                % Ensure any controls are created
                obj.CreateVisibleComponents;
            end
                
            % Make the graphical object visible
            obj.UpdateAllComponentVisibility;
        end
        
        function Disable(obj)
            % Disables this interface component
            
            obj.Enabled = false;
            
            % Set the flag determining inherited enabled-ness for this window and all children
            obj.SetAllParentEnabled(obj.ParentWindowEnabled);
            
            % Make the graphical object hidden
            obj.UpdateComponentVisibility;
        end
        
        function Show(obj)
            % Makes this component visible and all of its children (unless they
            % have been disabled)
            
            % Set the visibility flag for this window and all children
            obj.SetAllParentVisibility(true);
            
            % Ensure any controls are created
            obj.CreateVisibleComponents;
            
            % Make the graphical object visible
            obj.UpdateAllComponentVisibility;
        end

        function Hide(obj)
            % Hide this interface component and its children. This prevents
            % unnecessary creation and modification of components when they are
            % hidden
            obj.ParentWindowVisible = false;

            % Make the graphical object hidden
            obj.UpdateComponentVisibility;

            % Hide all the child components
            for child = obj.Children
                child{1}.Hide;
            end
        end
     
        function is_visible = IsVisible(obj)
            is_visible = obj.Enabled && obj.ParentWindowVisible && obj.ParentWindowEnabled;
        end
        
        function handle = GetContainerHandle(obj)
            handle = obj.GraphicalComponentHandle;
            if isempty(obj.GraphicalComponentHandle)
                if obj.ComponentHasBeenCreated
                    handle = obj.Parent.GetContainerHandle;
                else
                    obj.Reporting.Error('GemUserInterfaceObject:HandleRequestedBeforeCreation', 'GetContainerHandle() was called before the component was created');
                end
            end
        end
        
        function screen_coords = GetScreenPosition(obj)
            if isempty(obj.Parent)
                screen_coords = [1, 0];
            else
                screen_coords = obj.ChildToParentCoordinates(obj.Parent.GetScreenPosition);
            end
            
        end
        
        function child_coords = ParentToChildCoordinates(obj, parent_coords)
            component_position = obj.Position;
            child_coords = parent_coords - component_position(1:2) + 1;
        end
        
        function parent_coords = ChildToParentCoordinates(obj, child_coords)
            component_position = obj.Position;
            parent_coords = child_coords + component_position(1:2) - 1;
        end
        
        function figure_handle = GetParentFigure(obj)
            % Returns handle to the GemFigure parent object
            
            figure_handle = obj;
            while ~isempty(figure_handle) && ~isa(figure_handle, 'GemFigure')
                figure_handle = figure_handle.Parent;
            end
            
        end
        
        function ShowWaitCursor(obj)
            obj.GetParentFigure.ShowWaitCursor;
        end
        
        function HideWaitCursor(obj)
            obj.GetParentFigure.HideWaitCursor;
        end
        
        function SendToBottom(obj, bottom_component)
            if obj.ComponentHasBeenCreated && bottom_component.ComponentHasBeenCreated
                
                child_handles = get(obj.GraphicalComponentHandle, 'Children');
                handle_for_bottom = bottom_component.GraphicalComponentHandle;
                other_handles = setdiff(child_handles, handle_for_bottom);
                reordered_handles = [other_handles; handle_for_bottom];
                set(obj.GraphicalComponentHandle, 'Children', reordered_handles);
            end
        end        
    end

    methods (Access = protected)
        
        function PostCreation(obj, position)
            % Called after the component and all its children have been created
        end
        
        function SetAllParentVisibility(obj, visible)
            % Recursively sets visibility of all components to true
            obj.ParentWindowVisible = visible;
            for child = obj.Children
                child{1}.SetAllParentVisibility(visible);
            end
        end

        function SetAllParentEnabled(obj, enabled)
            % Recursively sets parent enabled flag of all components
            obj.ParentWindowEnabled = enabled;
            for child = obj.Children
                child{1}.SetAllParentEnabled(enabled && obj.Enabled);
            end
        end
        
        function CreateVisibleComponents(obj)
            % Creates graphical controls for all visible objects
            if obj.IsVisible
                
                % Create this component if necessary
                if ~obj.ComponentHasBeenCreated
                    if isempty(obj.Position)
                        obj.Reporting.Error('GemUserInterfaceObject:NoSizeSet', 'The control does not have a valid position because the Resize() function has not been called. This error may be caused if you forget to add a GemUserInterfaceObject to its parent using AddChild().');
                    end
                    obj.CreateGuiComponent(obj.Position);

                    % Ensure the parent GemFigure receives keyboard input from this control
                    obj.CaptureKeyboardInput;
                    
                    obj.ComponentHasBeenCreated = true;
                    obj.LastHandlePosition = obj.Position;
                    obj.LastHandleVisible = [];
                end
                
                % In some cases child obejcts may be created after the last
                % resize, so they don't have a default position. We fix this by
                % forcing a resize of the parent before creating the components of the child
                if obj.ResizeRequired
                    obj.Resize(obj.Position)
                    obj.ResizeRequired = false;
                end
                
                % Iterate through children and call this method recursively
                for child = obj.Children
                    child{1}.CreateVisibleComponents;
                end
                
                obj.PostCreation(obj.Position);
            end
        end

        function UpdateComponentVisibility(obj)
            % Change the visibility of the uicomponent in the Handle
            
            if obj.ComponentHasBeenCreated
                is_visible = obj.IsVisible;
                
                % If there is no underlying graphical object, we apply visibility to all the
                % child objects
                if isempty(obj.GraphicalComponentHandle)
                    if ~is_visible
                        for child = obj.Children
                            child{1}.UpdateComponentVisibility;
                        end
                    end
                else
                    
                    if is_visible
                        % Show the component if it is hidden, or update the position if it has changed
                        if isempty(obj.LastHandleVisible) || isequal(obj.LastHandleVisible, false) || (~isequal(obj.LastHandlePosition, obj.Position))
                            set(obj.GraphicalComponentHandle, 'Visible', obj.VisibleParameter, 'Position', obj.Position);
                            obj.LastHandleVisible = true;
                            obj.LastHandlePosition = obj.Position;
                        end
                        
                    else
                        % Hide the component if necessary
                        if isempty(obj.LastHandleVisible) || obj.LastHandleVisible
                            set(obj.GraphicalComponentHandle, 'Visible', 'off');
                            obj.LastHandleVisible = false;
                        end
                    end
                end
            end
        end
        
        function UpdateAllComponentVisibility(obj)
            % Updates this visibility of this component and all its children
            for child = obj.Children
                child{1}.UpdateAllComponentVisibility;
            end
            
            obj.UpdateComponentVisibility;
            
        end
        
        function input_has_been_processed = MouseDown(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is clicked inside the control
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MouseUp(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is clicked inside the control
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = Keypressed(obj, click_point, key, src, eventdata)
            % This method is called when the mouse is clicked inside the control
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is moved
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MouseExit(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse exits a control which previously
            % processed a MouseHasMoved event
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MouseDragged(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is moved
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = Scroll(obj, click_point, scroll_count, sr, eventdata)
            % This method is called when the mouse is clicked inside the control
            input_has_been_processed = false;
        end

        function ProcessActivityToSpecificObject(obj, processing_object, function_name, click_point, varargin)
            % Sends an activity to a specific user interface object
            
            % Get the coordinates relative to the child
            child_coordinates = obj.GetChildCoordinates(processing_object, click_point);
            
            % Call the function on the specified object with the modified coordinates
            processing_object.(function_name)(child_coordinates, varargin{:});            
        end
        
        function processing_object = ProcessActivity(obj, function_name, click_point, varargin)
            % Send a mouse down call to the right component
            
            if obj.IsVisible
                if obj.IsPointInControl(click_point)
                    
                    new_click_point = obj.ParentToChildCoordinates(click_point);
                    
                    % Try iterating through the children to process the
                    % action
                    for child = obj.Children
                        processing_object = child{1}.ProcessActivity(function_name, new_click_point, varargin{:});
                        if ~isempty(processing_object)
                            return;
                        end
                    end
                    
                    % Otherwise try to get this control itself to handle the action
                    if obj.(function_name)(new_click_point, varargin{:});
                        processing_object = obj;
                    else
                        processing_object = [];
                    end
                    return;
                end
            end
            
            % Action was not handled
            processing_object = [];
        end

        function click_point = GetChildCoordinates(obj, child_object, click_point)
            % Modifies coordinates to they are relative to a child object
            
            % Create a stack of objects in the parent-child hierarchy
            object_hierarchy = obj.GetObjectHierarchy(child_object);
            
            % Use the hierarchy to modify the coordinates
            while ~object_hierarchy.IsEmpty
                next_object = object_hierarchy.Pop;
                click_point = next_object.ParentToChildCoordinates(click_point);
            end
        end
                
        
        function object_hierarchy = GetObjectHierarchy(obj, processing_object)
            object_hierarchy = CoreStack;
            while (obj ~= processing_object && isvalid(processing_object))
                object_hierarchy.Push(processing_object);
                processing_object = processing_object.Parent;
            end
            if isvalid(processing_object)
                object_hierarchy.Push(processing_object);
            end
        end
        
        function CaptureKeyboardInput(obj)
            if ~isempty(obj.GraphicalComponentHandle)
                controls = findobj(obj.GraphicalComponentHandle, 'Style','pushbutton', '-or', 'Style', 'checkbox', '-or', 'Style', 'togglebutton', '-or', 'Style', 'text', '-or', 'Style', 'slider', '-or', 'Style', 'popupmenu');
                for control = controls
                    parent = obj.GetParentFigure;
                    set(control, 'KeyPressFcn', @parent.CustomKeyPressedFunction);
                end
            end
        end
    
        function RestoreCustomKeyPressCallback(obj)
            % For certain tools, Matlab will replace the keyboard/mouse
            % handlers with its own handlers, so we need to change them
            % back in order to handle our own shortcuts. However, Matlab
            % has listeners which prevent changing of these when the
            % mode is active. We need to first disable these listeners.
            
            try
                obj.DisableMatlabHandleListeners
                obj.AddCustomKeyHandlers;
            catch ex
                % An error here could be a change in internal
                % implementaton of Matlab hg
                obj.Reporting.ShowWarning('GemFigure:FailedToRestoreWindowListenerHandles', 'An error occurred while attempting to restore custom key callbacks', ex);
            end
        end
        
        function DisableMatlabHandleListeners(obj)
            % Matlab has listeners which prevent changing of keyboard/mouse
            % callbacks when certain modes are active. We need to first
            % disable these listeners before we can set the custom
            % listeners.
            %
            % Further complications result in changes in Matlab's hg2
            %
            % See here for more information: http://undocumentedmatlab.com/blog/enabling-user-callbacks-during-zoom-pan
            
            hManager = uigetmodemanager(obj.GetParentFigure.GetContainerHandle);
            try
                % This code should work with Matlab hg1 but will throw
                % an exception in Matlab hg2
                set(hManager.WindowListenerHandles, 'Enable', 'off');
            catch
                % This code should work with Matlab hg2
                [hManager.WindowListenerHandles.Enabled] = deal(false);
            end

        end
        
        function ClearCallbacks(obj)
            obj.KeyPressFcn = [];
            obj.WindowScrollWheelFcn = [];
            obj.WindowButtonUpFcn = [];
            obj.WindowButtonDownFcn = [];
            obj.WindowButtonMotionFcn = [];
        end
        
        function AddCustomKeyHandlers(obj)
            % Store Matlab's callbacks for mouse and key events and replace
            % with custom handlers. This allows us to choose for each
            % control whether we want Matlab to handle the callback or if
            % we want to handle it ourselves.
            
            parent_figure = obj.GetParentFigure;
            obj.ReplaceCallback('KeyPressFcn', 'CustomKeyPressedFunction', @parent_figure.CustomKeyPressedFunction);
            obj.ReplaceCallback('WindowScrollWheelFcn', 'CustomWindowScrollWheelFunction', @parent_figure.CustomWindowScrollWheelFunction);
            obj.ReplaceCallback('WindowButtonDownFcn', 'CustomWindowButtonDownFunction', @parent_figure.CustomWindowButtonDownFunction);
            obj.ReplaceCallback('WindowButtonUpFcn', 'CustomWindowButtonUpFunction', @parent_figure.CustomWindowButtonUpFunction);
            obj.ReplaceCallback('WindowButtonMotionFcn', 'CustomWindowButtonMotionFunction', @parent_figure.CustomWindowButtonMotionFunction);
        end        
        
        function ReplaceCallback(obj, property, gem_callback_name, gem_callback)
            parent_figure = obj.GetParentFigure;
            component = parent_figure.GraphicalComponentHandle;
            current_callback = get(component, property);
            if isempty(current_callback) || iscell(current_callback) || isempty(strfind(char(current_callback), gem_callback_name))
                obj.(property) = current_callback;
                set(component, property, gem_callback);
            end
        end
        
        function input_has_been_processed = MatlabKeypressed(obj, click_point, key)
            % This method is called when the mouse is clicked inside the control

            if ~isempty(obj.KeyPressFcn)
                obj.KeyPressFcn{1}(src, eventdata, obj.KeyPressFcn{2:end});
                input_has_been_processed = true;
                return
            end
            
            input_has_been_processed = false;
        end
        
        
        function input_has_been_processed = MatlabMouseDown(obj, click_point, selection_type, src, eventdata)
            % Let Matlab callbacks process this mouse down event
            
            if ~isempty(obj.WindowButtonDownFcn)
                obj.WindowButtonDownFcn{1}(src, eventdata, obj.WindowButtonDownFcn{2:end});
                input_has_been_processed = true;
                return
            end
            
            input_has_been_processed = false;
        end

        function input_has_been_processed = MatlabMouseUp(obj, click_point, selection_type, src, eventdata)
            % Let Matlab callbacks process this mouse up event

            if ~isempty(obj.WindowButtonUpFcn)
                obj.WindowButtonUpFcn{1}(src, eventdata, obj.WindowButtonUpFcn{2:end});
                input_has_been_processed = true;
                return
            end
            
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MatlabMouseHasMoved(obj, click_point, selection_type, src, eventdata)
            % Let Matlab callbacks process this mouse moved event

            if ~isempty(obj.WindowButtonMotionFcn)
                obj.WindowButtonMotionFcn(src, eventdata);
                input_has_been_processed = true;
                return
            end
            
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MatlabMouseDragged(obj, click_point, selection_type, src, eventdata)
            % Let Matlab callbacks process this mouse dragged event

            if ~isempty(obj.WindowButtonMotionFcn)
                obj.WindowButtonMotionFcn(src, eventdata);
                input_has_been_processed = true;
                return
            end
            
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MatlabScroll(obj, click_point, scroll_count, src, eventdata)
            % Let Matlab callbacks process this scroll event
            
            if ~isempty(obj.WindowScrollWheelFcn)
                obj.WindowScrollWheelFcn{1}(src, eventdata, obj.WindowScrollWheelFcn{2:end});
                input_has_been_processed = true;
                return
            end
            
            input_has_been_processed = false;
        end
        
    end
    
    methods (Access = private)
        
        function SetParent(obj, parent)
            obj.Parent = parent;
            obj.SetAllParentEnabled(parent.ParentWindowEnabled);
            obj.SetAllParentVisibility(parent.ParentWindowVisible);
        end
        
        function point_within_control = IsPointInControl(obj, point_coords)
            component_position = obj.Position;
            point_within_control = false;
            
            if obj.IsVisible
                if (point_coords(1) >= component_position(1) && point_coords(2) >= component_position(2) && ...
                        point_coords(1) < component_position(1) + component_position(3) && ...
                        point_coords(2) < component_position(2) + component_position(4)) 
                    point_within_control = true;
                end
            end
        end
        
    end
    
    methods (Access = protected, Static)
        
        function DeleteIfValidObject(handle)
            % Removes an object
            
            CoreSystemUtilities.DeleteIfValidObject(handle);
        end
        
        function DeleteIfGraphicsHandle(handle)
            % Removes a graphics handle
            
            CoreSystemUtilities.DeleteIfGraphicsHandle(handle);
        end
    end
    
end