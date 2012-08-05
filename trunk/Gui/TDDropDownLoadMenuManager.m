classdef TDDropDownLoadMenuManager < handle
    % TDDropDownLoadMenuManager. Part of the gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %     TDDropDownLoadMenuManager stores the menu entries in the drop-down
    %     quick load menu at the top of the gui. Each entry contains a
    %     TDImageInfo object which contains the filenames, path and uid for a
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
    end
    
    methods
        function obj = TDDropDownLoadMenuManager(settings, popupmenu_handle)
            obj.MenuHandle = popupmenu_handle;
            obj.Settings = settings;
            obj.UpdateQuickLoadMenu;
        end
        
        function UpdateQuickLoadMenu(obj)
            prev_infos = obj.Settings.PreviousImageInfos;
            if isempty(prev_infos)
                return
            end
            
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
            
            popupmenu_argument = prev_paths{1};
            for i = 2:length(prev_paths)
                popupmenu_argument = [popupmenu_argument '|' prev_paths{i}];
            end
            
            uids = prev_infos.keys;
            if ~isempty(obj.Settings.ImageInfo) && ~isempty(obj.Settings.ImageInfo.ImageUid)
                current_uid = obj.Settings.ImageInfo.ImageUid;
                current_number = find(ismember(uids, current_uid), 1);
                set(obj.MenuHandle, 'Value', current_number);
            end
            set(obj.MenuHandle, 'String', popupmenu_argument);
        end
        
        function image_info = GetImageInfoForIndex(obj, index)
            previous_infos = obj.Settings.PreviousImageInfos;
            if isempty(previous_infos)
                image_info = [];
            else
                values = previous_infos.values;
                image_info = values{index};
                image_uid = image_info.ImageUid;

                % If the selected entry is the currenyly loaded dataset then do
                % nothing
                if ~isempty(obj.Settings.ImageInfo) && ~isempty(obj.Settings.ImageInfo.ImageUid)                
                    if strcmp(image_uid, obj.Settings.ImageInfo.ImageUid)
                        image_info = [];
                    end
                end
            end
        end
    end
    
end

