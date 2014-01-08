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
        Enabled
        Position
        GraphicalComponentHandle % Handle to the uicontrol/uipanel object (if there is one)
        ComponentHasBeenCreated
        LockResize     % Flag prevents user control from being resized
        ResizeRequired % Flag indicates that a Resize() needs to be called before child controls can be created
        
        LastHandlePosition % Stores the last position set to the handle of the graphics component
        LastHandleVisible  % Stores the last visibility state set to the handle of the graphics component

    end
    
    methods (Abstract)
        CreateGuiComponent(obj, position, reporting)
    end
    
    methods
        function obj = PTKUserInterfaceObject(parent)
            if nargin > 0
                obj.Parent = parent;
            end
            if isempty(parent)
                obj.ParentWindowVisible = false;
            else
                obj.ParentWindowVisible = parent.ParentWindowVisible;
            end
            obj.Enabled = true;
            obj.ComponentHasBeenCreated = false;
            obj.Children = [];
            obj.ResizeRequired = false;
            obj.LockResize = false;
        end
        
        function delete(obj)
            for child = obj.Children
                delete(child{1});
            end
            obj.DeleteIfHandle(obj.GraphicalComponentHandle);
        end
        
        function AddChild(obj, child, reporting)
            if ~isa(child, 'PTKUserInterfaceObject')
                reporting.Error('PTKUserInterfaceObject:ChildNotAPTKUserInterfaceObject', 'This child obect passed to AddChild is not of type PTKUserInterfaceObject');
            end
            obj.Children{end + 1} = child;
            obj.ResizeRequired = true;
        end
        
        function Resize(obj, new_position)
            obj.ResizeRequired = false;
            if ~isempty(obj.GraphicalComponentHandle) && obj.IsVisible && ~obj.LockResize
                set(obj.GraphicalComponentHandle, 'Position', new_position);
                obj.LastHandlePosition = new_position;
            end
            obj.Position = new_position;
        end
        
        
        function height = GetRequestedHeight(~)
            % Returns a value for the height of the object. A null value indicates
            % the caller can choose the height
            height = [];
        end
        
        
        function Enable(obj, reporting)
            % Enables this component
            obj.Enabled = true;
            
            % Ensure any controls are created
            obj.CreateVisibleComponents(reporting);
            
            % Make the graphical object visible
            obj.UpdateComponentVisibility;
        end
        
        function Disable(obj)
            % Disables this interface component
            obj.Enabled = false;
            
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
            obj.UpdateAllComponentVisibility(reporting);
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
            is_visible = obj.Enabled && obj.ParentWindowVisible;
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
    end

    methods (Access = protected)
        
        function SetAllVisibility(obj)
            % Recursively sets visibility of all components to true
            obj.ParentWindowVisible = true;
            for child = obj.Children
                child{1}.SetAllVisibility;
            end
        end

        function CreateVisibleComponents(obj, reporting)
            % Creates graphical controls for all visible objects
            if obj.IsVisible
                
                % Create this component if necessary
                if ~obj.ComponentHasBeenCreated
                    if isempty(obj.Position)
                        reporting.Error('PTKUserInterfaceObject:NoSizeSet', 'The control does not have a valid position because the Resize() function has not been called.');
                    end
                    obj.CreateGuiComponent(obj.Position, reporting);
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
            end
        end

        function UpdateComponentVisibility(obj)
            % Change the visibility of the uicomponent in the Handle
            
            if ~isempty(obj.GraphicalComponentHandle)
                is_visible = obj.IsVisible;
                
                if is_visible
                    % Show the component if it is hidden, or update the position if it has changed
                    if isequal(obj.LastHandleVisible, false) || (~isequal(obj.LastHandlePosition, obj.Position))
                        set(obj.GraphicalComponentHandle, 'Visible', 'on', 'Position', obj.Position);
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
        
        function UpdateAllComponentVisibility(obj, reporting)
            % Updates this visibility of this component and all its children
            for child = obj.Children
                child{1}.UpdateAllComponentVisibility(reporting);
            end
            
            obj.UpdateComponentVisibility;
            
        end
        
        function input_has_been_processed = MouseDown(obj, click_point)
            % This method is called when the mouse is clicked inside the control
            input_has_been_processed = false;
        end
        
        function child_coords = ParentToChildCoordinates(obj, parent_coords)
            component_position = obj.Position;
            child_coords = parent_coords - component_position(1:2) + 1;
        end
        
        function input_has_been_processed = CallMouseDown(obj, click_point)
            % Called when the mousewheel is used to scroll
            
            component_position = obj.Position;
            
            if obj.IsVisible
                if (click_point(1) >= component_position(1) && click_point(2) >= component_position(2) && ...
                        click_point(1) < component_position(1) + component_position(3) && ...
                        click_point(2) < component_position(2) + component_position(4))
                    
                    new_click_point = obj.ParentToChildCoordinates(click_point);
                    
                    % If the action was inside this control, then we treat as
                    % handled
                    input_has_been_processed = true;
                    
                    if obj.MouseDown(new_click_point)
                        % This object has handled the click, so we exit
                        return;
                    else
                        % Try iterating through the children to process the
                        % action
                        for child = obj.Children;
                            if child{1}.CallMouseDown(new_click_point);
                                return;
                            end
                        end
                    end
                end
            end
            
            % Action was not handled
            input_has_been_processed = false;
        end
    end
    
    methods (Access = protected, Static)
        
        function DeleteIfHandle(handle)
            % Removes a graphics handle
            if ishandle(handle)
                delete(handle)
            end
        end
        
    end
    
end