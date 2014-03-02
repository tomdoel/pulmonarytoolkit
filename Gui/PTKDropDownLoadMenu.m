classdef PTKDropDownLoadMenu < PTKDropDownMenu
    % PTKDropDownLoadMenu. Part of the gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %     PTKDropDownLoadMenu stores the menu entries in the drop-down
    %     quick load menu at the top of the gui. Each entry contains a
    %     PTKImageInfo object which contains the filenames, path and uid for a
    %     dataset, so that this dataset can be loaded when selected from the
    %     menu. New entries are added when datasets are imported, and this
    %     information is stored in the settings file so that is is remembered
    %     between sessions.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties (Access = private)
        Gui
        Settings
        SortedUidList
    end
    
    methods
        function obj = PTKDropDownLoadMenu(parent, gui, settings)
            obj = obj@PTKDropDownMenu(parent, 'Recent datasets', 'Select a dataset from a list of recently loaded datasets', []);
            obj.Gui = gui;
            obj.Settings = settings;
        end
        
        function UpdateQuickLoadMenu(obj, sorted_paths, sorted_uids)
            % Updates the items in the drop-down menu to match the specified paths and uids,
            % and selects the current dataset
            
            obj.SortedUidList = sorted_uids;
            obj.SetMenuText(sorted_paths);
            obj.SelectCurrentlyLoadedDataset;
        end
        
    end
    
    methods (Access = protected)
        
        function PopupmenuCallback(obj, hObject, ~, ~)
            % We replace the default callback with one that directly calls the GUI
            
            % Item selected from the pop-up menu
            index = get(hObject, 'Value');
            
            % Get the UID of the newly selected dataset
            selected_image_uid = obj.GetImageUidForIndex(index);
            
            obj.Gui.LoadFromPopupMenu(selected_image_uid);
        end        

    end
    
    
    methods (Access = private)
        
        function SetMenuText(obj, sorted_paths)
            % Set the contents of the drop-down menu
            
            popupmenu_argument = 'No dataset';
            for index = 1 : length(sorted_paths)
                popupmenu_argument = [popupmenu_argument '|' sorted_paths{index}];
            end
            obj.SetMenuItems(popupmenu_argument);
        end
        
        function SelectCurrentlyLoadedDataset(obj)
            % Change the currently selected dataset to match the one loaded in the Gui
            
            loaded_index = obj.GetCurrentlyLoadedInfoIndex;            
            if isempty(loaded_index)
                loaded_index = 1;
            else
                loaded_index = loaded_index + 1;
            end
            
            obj.SetSelectedIndex(loaded_index);
        end
        
        function current_index = GetCurrentlyLoadedInfoIndex(obj)
            % Returns the index of the drop down menu item which corresponds to the
            % currently loaded dataset. An empty value means 'No Dataset'
            
            current_index = [];
            uids = obj.SortedUidList;
            if ~isempty(obj.Settings.ImageInfo) && ~isempty(obj.Settings.ImageInfo.ImageUid)
                current_uid = obj.Settings.ImageInfo.ImageUid;
                current_index = find(ismember(uids, current_uid), 1);
            end
        end
        
        function image_uid = GetImageUidForIndex(obj, index)
            % Returns the series UID of the dataset corresponding to the menu item specified
            % by index
            
            previous_uids = obj.SortedUidList;
            if isempty(previous_uids) || (index == 1)
                image_uid = [];
            else
                image_uid = previous_uids{index - 1};
            end
        end
        
    end    
end

