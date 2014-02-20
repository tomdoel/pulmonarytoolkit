classdef PTKDropDownLoadMenuManager < handle
    % PTKDropDownLoadMenuManager. Part of the gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %     PTKDropDownLoadMenuManager stores the menu entries in the drop-down
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
        MenuHandle
        ImageDatabase
        Settings
        SortedUidList
    end
    
    methods
        function obj = PTKDropDownLoadMenuManager(settings, popupmenu_handle, image_database)
            obj.MenuHandle = popupmenu_handle;
            obj.Settings = settings;
            obj.ImageDatabase = image_database;
            
            % There is no need to call obj.UpdateQuickLoadMenu here provided the
            % menu is always updated after the first load in PTKGui.
            % Update can be a bit slow so we don't want to call it twice on
            % startup.
        end
        
        function UpdateQuickLoadMenu(obj)
            [sorted_paths, sorted_uids] = obj.ImageDatabase.GetListOfPaths;
            
            obj.SortedUidList = sorted_uids;
            
            obj.SetMenuText(sorted_paths);

            obj.SelectCurrentlyLoadedDataset;
        end
        
        function image_uid = GetImageUidForIndex(obj, index)
            previous_uids = obj.SortedUidList;
            if isempty(previous_uids) || (index == 1)
                image_uid = [];
            else
                image_uid = previous_uids{index - 1};
            end
        end
        
    end
    
    methods (Access = private)
        
        function SetMenuText(obj, sorted_paths)
            popupmenu_argument = 'No dataset';
            for index = 1 : length(sorted_paths)
                popupmenu_argument = [popupmenu_argument '|' sorted_paths{index}];
            end
            set(obj.MenuHandle, 'String', popupmenu_argument);
        end
        
        function SelectCurrentlyLoadedDataset(obj)
            % Ensure the currently loaded dataset is selected
            loaded_index = obj.GetCurrentlyLoadedInfoIndex;            
            if isempty(loaded_index)
                loaded_index = 1;
            else
                loaded_index = loaded_index + 1;
            end
            
            current_index = get(obj.MenuHandle, 'Value');
            if (current_index ~= loaded_index)
                set(obj.MenuHandle, 'Value', loaded_index);
            end
        end
        
        % Returns the index of the drop down menu item which corresponds to the
        % currently loaded dataset. An empty value means 'No Dataset'.
        function current_index = GetCurrentlyLoadedInfoIndex(obj)
            current_index = [];
            uids = obj.SortedUidList;
            if ~isempty(obj.Settings.ImageInfo) && ~isempty(obj.Settings.ImageInfo.ImageUid)
                current_uid = obj.Settings.ImageInfo.ImageUid;
                current_index = find(ismember(uids, current_uid), 1);
            end
        end
        
    end    
end

