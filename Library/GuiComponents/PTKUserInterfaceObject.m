classdef PTKUserInterfaceObject < handle
    % PTKUserInterfaceObject. Base class for PTK user interface components
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

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

        EventListeners
        
        VisibleParameter = 'on' % Defines the argument for component visibility
    end
    
    methods (Abstract)
        CreateGuiComponent(obj, position, reporting)
    end
    
    events
        ControlCreated
    end    
    
    methods
        function obj = PTKUserInterfaceObject(parent)
            if nargin > 0
                obj.Parent = parent;
            end
            if isempty(parent)
                obj.ParentWindowVisible = false;
                obj.ParentWindowEnabled = true;
            else
                obj.ParentWindowVisible = parent.ParentWindowVisible;
                obj.ParentWindowEnabled = parent.ParentWindowEnabled;
            end
            obj.Enabled = true;
            obj.ComponentHasBeenCreated = false;
            obj.Children = [];
            obj.ResizeRequired = false;
            obj.LockResize = false;
        end
        
        function delete(obj)
            delete(obj.EventListeners);

            for child = obj.Children
                delete(child{1});
            end
            obj.DeleteIfHandle(obj.GraphicalComponentHandle);
        end
        
        function AddChild(obj, child, reporting)
            % Add a child object to this object. After creating a PTKUserInterfaceObject,
            % you must call this method on the parent object in order to add the new object.
            
            if ~isa(child, 'PTKUserInterfaceObject')
                reporting.Error('PTKUserInterfaceObject:ChildNotAPTKUserInterfaceObject', 'This child obect passed to AddChild is not of type PTKUserInterfaceObject');
            end
            obj.Children{end + 1} = child;
            obj.ResizeRequired = true;
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
        
        
        function Enable(obj, reporting)
            % Enables this component
            
            if ~obj.Enabled
                obj.Enabled = true;
                
                % Set the flag determining inherited enabled-ness for this window and all children
                obj.SetAllParentEnabled(obj.ParentWindowEnabled);
                
                % Ensure any controls are created
                obj.CreateVisibleComponents(reporting);
                
                % Fire an event to indicate the control has just been created
                notify(obj, 'ControlCreated');
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
        
        function Show(obj, reporting)
            % Makes this component visible and all of its children (unless they
            % have been disabled)
            
            % Set the visibility flag for this window and all children
            obj.SetAllVisibility;
            
            % Ensure any controls are created
            obj.CreateVisibleComponents(reporting);
            
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
        
        function handle = GetContainerHandle(obj, reporting)
            handle = obj.GraphicalComponentHandle;
            if isempty(obj.GraphicalComponentHandle)
                if obj.ComponentHasBeenCreated
                    handle = obj.Parent.GetContainerHandle(reporting);
                else
                    reporting.Error('PTKUserInterfaceObject:HandleRequestedBeforeCreation', 'GetContainerHandle() was called before the component was created');
                end
            end
        end
        
        function child_coords = ParentToChildCoordinates(obj, parent_coords)
            component_position = obj.Position;
            child_coords = parent_coords - component_position(1:2) + 1;
        end
        
        function figure_handle = GetParentFigure(obj)
            % Returns handle to the PTKFigure parent object
            
            figure_handle = obj;
            while ~isempty(figure_handle) && ~isa(figure_handle, 'PTKFigure')
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
        
        function AddEventListener(obj, control, event_name, function_handle)
            % Adds a new event listener tied to the lifetime of this object
            new_listener = addlistener(control, event_name, function_handle);
            if isempty(obj.EventListeners)
                obj.EventListeners = new_listener;
            else
                obj.EventListeners(end + 1) = new_listener;
            end
        end
        
        function PostCreation(obj, position, reporting)
            % Called after the compent and all its children have been created
        end
        
        function SetAllVisibility(obj)
            % Recursively sets visibility of all components to true
            obj.ParentWindowVisible = true;
            for child = obj.Children
                child{1}.SetAllVisibility;
            end
        end

        function SetAllParentEnabled(obj, enabled)
            % Recursively sets parent enabled flag of all components
            obj.ParentWindowEnabled = enabled;
            for child = obj.Children
                child{1}.SetAllParentEnabled(enabled && obj.Enabled);
            end
        end
        
        function CreateVisibleComponents(obj, reporting)
            % Creates graphical controls for all visible objects
            if obj.IsVisible
                
                % Create this component if necessary
                if ~obj.ComponentHasBeenCreated
                    if isempty(obj.Position)
                        reporting.Error('PTKUserInterfaceObject:NoSizeSet', 'The control does not have a valid position because the Resize() function has not been called. This error may be caused if you forget to add a PTKUserInterfaceObject to its parent using AddChild().');
                    end
                    obj.CreateGuiComponent(obj.Position, reporting);

                    % Ensure the parent PTKFigure receives keyboard input from this control
                    obj.CaptureKeyboardInput;
                    
                    obj.ComponentHasBeenCreated = true;
                    obj.LastHandlePosition = obj.Position;
                    obj.LastHandleVisible = false;
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
                    child{1}.CreateVisibleComponents(reporting);
                end
                
                obj.PostCreation(obj.Position, reporting);
            end
        end

        function UpdateComponentVisibility(obj)
            % Change the visibility of the uicomponent in the Handle
            
            if ~isempty(obj.GraphicalComponentHandle)
                is_visible = obj.IsVisible;
                
                if is_visible
                    % Show the component if it is hidden, or update the position if it has changed
                    if isequal(obj.LastHandleVisible, false) || (~isequal(obj.LastHandlePosition, obj.Position))
                        set(obj.GraphicalComponentHandle, 'Visible', obj.VisibleParameter, 'Position', obj.Position);
                        obj.LastHandleVisible = true;
                        obj.LastHandlePosition = obj.Position;
                    end
                    
                else
                    % Hide the component if necessary
                    if obj.LastHandleVisible
                        set(obj.GraphicalComponentHandle, 'Visible', 'off');
                        obj.LastHandleVisible = false;
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
        
        function input_has_been_processed = MouseDown(obj, click_point, selection_type, src)
            % This method is called when the mouse is clicked inside the control
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MouseUp(obj, click_point, selection_type, src)
            % This method is called when the mouse is clicked inside the control
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = Keypressed(obj, click_point, key)
            % This method is called when the mouse is clicked inside the control
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src)
            % This method is called when the mouse is moved
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MouseExit(obj, click_point, selection_type, src)
            % This method is called when the mouse exits a control which previously
            % processed a MouseHasMoved event
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = MouseDragged(obj, click_point, selection_type, src)
            % This method is called when the mouse is moved
            input_has_been_processed = false;
        end
        
        function input_has_been_processed = Scroll(obj, click_point, scroll_count)
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
                    for child = obj.Children;
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
            object_hierarchy = PTKStack;
            while (obj ~= processing_object)
                object_hierarchy.Push(processing_object);
                processing_object = processing_object.Parent;
            end
            object_hierarchy.Push(processing_object);
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
    
    end
    
    methods (Access = private)
        
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
        
        function DeleteIfHandle(handle)
            % Removes a graphics handle
            
            PTKSystemUtilities.DeleteIfHandle(handle);
        end
        
    end
    
end