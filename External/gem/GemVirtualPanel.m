classdef GemVirtualPanel < GemUserInterfaceObject
    % GemVirtualPanel GEM class for a panel which has no underlying graphical component.
    %
    %     GemVirtualPanel represents a GEM panel which does not have an underlying
    %     Matlab panel component. In other words, the VirtualPanel acts like a real
    %     panel to GEM, but any Matlab components which act on it are actually
    %     acting on the parent panel handle.
    %
    %     The purpose of a GemVirtualPanel is to simplify user interface design by
    %     allowing the separation of a panel into smaller panels without introducing
    %     the overhead of creating additional graphical objects.
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    methods
        function obj = GemVirtualPanel(parent)
            obj = obj@GemUserInterfaceObject(parent);
        end
        
        function CreateGuiComponent(obj, position)
            % There is no underlying graphical object to create
        end

        function child_coords = ParentToChildCoordinates(obj, parent_coords)
            child_coords = parent_coords;
        end
        
        function parent_coords = ChildToParentCoordinates(obj, child_coords)
            parent_coords = child_coords;
        end        
    end
end