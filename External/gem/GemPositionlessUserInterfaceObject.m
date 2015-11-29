classdef GemPositionlessUserInterfaceObject < GemUserInterfaceObject
    % GemPositionlessUserInterfaceObject. Base class for GEM user interface
    % components whose Matlab objects do not have an underlying Position property
    %
    %     Use GemPositionlessUserInterfaceObject for user interface objects which
    %     are graphical components but do not have a Position property
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    methods
        function obj = GemPositionlessUserInterfaceObject(parent)
            obj = obj@GemUserInterfaceObject(parent);
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
                obj.LastHandlePosition = new_position;
            end
            obj.Position = new_position;
        end
        
        function ObjectHasBeenResized(obj)
            % GemPositionlessUserInterfaceObject has no position, so do nothing
        end
        
    end     
    
    methods (Access = protected)

        function UpdateComponentVisibility(obj)
            % Change the visibility of the uicomponent in the Handle
            
            if ~isempty(obj.GraphicalComponentHandle)
                is_visible = obj.IsVisible;
                
                if is_visible
                    % Show the component if it is hidden, or update the position if it has changed
                    if isequal(obj.LastHandleVisible, false)
                        set(obj.GraphicalComponentHandle, 'Visible', 'on');
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
    end
end