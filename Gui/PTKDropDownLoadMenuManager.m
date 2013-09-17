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
        Settings
        SortedInfoList
    end
    
    methods
        function obj = PTKDropDownLoadMenuManager(settings, popupmenu_handle)
            obj.MenuHandle = popupmenu_handle;
            obj.Settings = settings;
            obj.UpdateQuickLoadMenu;
        end
        
        function UpdateQuickLoadMenu(obj)
            prev_infos = obj.Settings.PreviousImageInfos;
            if isempty(prev_infos)
                sorted_infos = [];
                sorted_paths = [];
            else
                prev_paths = PTKDropDownLoadMenuManager.GetListOfPaths(prev_infos);
                
                [~, sorted_indices] = PTKTextUtilities.SortFilenames(prev_paths);
                sorted_paths = prev_paths(sorted_indices);
                sorted_infos = prev_infos.values;
                sorted_infos = sorted_infos(sorted_indices);
            end
            
            obj.SortedInfoList = sorted_infos;
            
            obj.SetMenuText(sorted_paths);

            obj.SelectCurrentlyLoadedDataset;
        end
        
        function image_info = GetImageInfoForIndex(obj, index)
            previous_infos = obj.SortedInfoList;
            if isempty(previous_infos) || (index == 1)
                image_info = [];
            else
                image_info = previous_infos{index - 1};
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
            uids = PTKContainerUtilities.GetFieldValuesFromSet(obj.SortedInfoList, 'ImageUid');
            if ~isempty(obj.Settings.ImageInfo) && ~isempty(obj.Settings.ImageInfo.ImageUid)
                current_uid = obj.Settings.ImageInfo.ImageUid;
                current_index = find(ismember(uids, current_uid), 1);
            end
        end
        
    end
    
    methods (Static, Access = private)
        
        % Constructs a list of paths from a list of PTKImageInfos.
        function prev_paths = GetListOfPaths(prev_infos)
            infos = prev_infos.values;
            prev_paths = [];
            for index = 1 : length(infos)
                if ~isempty(infos{index})
                    if isempty(infos{index}.ImageFilenames) || (length(infos{index}.ImageFilenames) > 1)
                        display_path = infos{index}.ImagePath;
                    else
                        display_path = fullfile(infos{index}.ImagePath, infos{index}.ImageFilenames{1});
                    end
                    prev_paths{index} = display_path;
                end
            end
        end
        
    end
    
end

