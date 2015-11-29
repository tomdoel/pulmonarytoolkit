classdef GemDropDownMenu < GemUserInterfaceObject
    % GemDropDownMenu GEM class for a pop-up menu control
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        Callback
        FontSize
        HorizontalAlignment
        MenuItems
        SelectedIndex
        Tag
        ToolTip
    end
    
    methods
        function obj = GemDropDownMenu(parent, menu_items, tooltip, callback)
            obj = obj@GemUserInterfaceObject(parent);
            
            obj.MenuItems = menu_items;
            obj.ToolTip = tooltip;
            obj.Callback = callback;
            obj.FontSize = 11;
            obj.HorizontalAlignment = 'left';
            obj.SelectedIndex = 1;
        end
        
        function delete(obj)
        end
        
        function CreateGuiComponent(obj, position)
            obj.GraphicalComponentHandle = uicontrol('Style', 'popupmenu', 'Parent', obj.Parent.GetContainerHandle, ...
                'FontAngle', 'normal', 'FontUnits', 'pixels', 'FontSize', obj.FontSize, 'HorizontalAlignment', obj.HorizontalAlignment, ...
                'Units', 'pixels', 'Position', position, 'ToolTipString', obj.ToolTip, 'String', obj.MenuItems, ...
                'Callback', @obj.PopupmenuCallback, 'Value', obj.SelectedIndex);

        end
        
        function SetMenuItems(obj, menu_items)
            obj.MenuItems = menu_items;
            if obj.ComponentHasBeenCreated
                set(obj.GraphicalComponentHandle, 'String', menu_items);
            end
        end
        
        function SetSelectedIndex(obj, selected_index)
            obj.SelectedIndex = selected_index;
            if obj.ComponentHasBeenCreated
                current_index = get(obj.GraphicalComponentHandle, 'Value');
                if (current_index ~= obj.SelectedIndex)
                    set(obj.GraphicalComponentHandle, 'Value', obj.SelectedIndex);
                end
            end
        end

    end
    
    methods (Access = protected)
        
        function PopupmenuCallback(obj, hObject, ~, ~)
            % Item selected from the pop-up menu
            obj.Callback(get(hObject, 'Value'));
        end        

    end
end