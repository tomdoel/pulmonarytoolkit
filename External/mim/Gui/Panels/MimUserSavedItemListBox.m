classdef MimUserSavedItemListBox < GemListBoxWithTitle
    % MimUserSavedItemListBox. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     MimUserSavedItemListBox is used to show lists of user-generated
    %     items such as markers and manual segmentations
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (Access = protected)
        GuiCallback
        ListCallback
        AddCallback
        GetCurrentCallback
        LoadCallback
        DeleteCallback
        ItemGenericName
    end
    
    events
        ListChanged
    end
    
    methods
        function obj = MimUserSavedItemListBox(parent, item_generic_name, load_callback, delete_callback, add_callback, list_callback, get_current_callback)
            obj = obj@GemListBoxWithTitle(parent, upper([item_generic_name 's']), ['Add ' item_generic_name], ['Delete ' item_generic_name]);
            obj.LoadCallback = load_callback;
            obj.DeleteCallback = delete_callback;
            obj.AddCallback = add_callback;
            obj.GetCurrentCallback = get_current_callback;
            obj.ListCallback = list_callback;
            obj.ItemGenericName = item_generic_name;
        end
        
        function UpdateForNewImage(obj, current_dataset, window, level)
            obj.Update();
        end
         
        function Update(obj)
            obj.ListBox.ClearItems;
            
            sets = obj.ListCallback();
            if ~isempty(sets)
                for index = 1 : length(sets)
                    this_set = sets{index};
                    this_item = MimUserSavedItem(obj.ListBox.GetListBox, this_set.Second, ['Select this ' obj.ItemGenericName], obj.LoadCallback, obj.DeleteCallback);

                    obj.ListBox.AddItem(this_item);
                end

                current_set = obj.GetCurrentCallback();
                
                % Resize as new sets may have been added
                if ~isempty(obj.Position)
                    obj.Resize(obj.Position);
                end
                obj.ListBox.SelectItem(current_set, true);
            end
            notify(obj, 'ListChanged');            
        end
        
        function SelectSetPanel(obj, set_name, selected)
            obj.ListBox.SelectItem(set_name, selected);
        end
    end
    
    methods (Access = protected)
        function AddButtonClicked(obj, ~, event_data)
            obj.AddCallback();
            obj.Update();
        end
        
        function DeleteButtonClicked(obj, ~, ~)
            current = obj.GetCurrentCallback();
            if ~isempty(current)
                obj.DeleteCallback(current);
            end
            obj.Update();
        end
    end
end