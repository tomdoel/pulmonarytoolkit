classdef MimOrganisedPlugins < CoreBaseClass
    % MimOrganisedPlugins. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        AppDef
        PluginGroups
        GuiApp
        OrganisedPluginsModeList
    end
    
    methods
        function obj = MimOrganisedPlugins(gui_app, plugin_cache, app_def, reporting)
            obj.AppDef = app_def;
            obj.GuiApp = gui_app;
            obj.OrganisedPluginsModeList = MimOrganisedPluginsModeList(plugin_cache);
            obj.Repopulate(reporting);
        end
        
        function Repopulate(obj, reporting)
            obj.OrganisedPluginsModeList.Clear;
            plugin_list = obj.GetListOfPossiblePluginNames;
            obj.OrganisedPluginsModeList.AddList(plugin_list, obj.GuiApp, reporting);
            gui_plugin_list = obj.GetListOfPossibleGuiPluginNames;
            obj.OrganisedPluginsModeList.AddList(gui_plugin_list, obj.GuiApp, reporting);
        end

        function plugin_list = GetAllPluginsForMode(obj, mode)
            plugin_list = obj.OrganisedPluginsModeList.GetPlugins(mode);
        end
        
        function tool_list = GetOrderedPlugins(obj, mode)
            tool_maps = obj.GetAllPluginsForMode(mode);
            tool_maps = tool_maps.values;
            tool_list = [];
            for tool_map = tool_maps
                tool_list = horzcat(tool_list, tool_map{1}.values);
            end
            locations = CoreContainerUtilities.GetMatrixOfFieldValuesFromSet(tool_list, 'Location');
            [~, index] = sort(locations, 'ascend');
            tool_list = tool_list(index);
        end        
    end    
    
    methods (Access = private)
        
        function combined_plugin_list = GetListOfPossiblePluginNames(obj)
            % Obtains a list of plugins found in the Plugins folder
            plugin_list = obj.GetListOfPlugins;
            if PTKSoftwareInfo.DemoMode
                combined_plugin_list = plugin_list;
            else
                user_plugin_list = obj.GetListOfUserPlugins;
                combined_plugin_list = horzcat(plugin_list, user_plugin_list);
            end
        end
        
        function combined_plugin_list = GetListOfPossibleGuiPluginNames(obj)
            % Obtains a list of Gui plugins found in the GuiPlugins folder
            plugin_list = PTKDirectories.GetListOfGuiPlugins;
            if PTKSoftwareInfo.DemoMode
                combined_plugin_list = plugin_list;
            else
                user_plugin_list = PTKDirectories.GetListOfUserGuiPlugins;
                combined_plugin_list = horzcat(plugin_list, user_plugin_list);
            end
        end
        
        function plugin_name_list = GetListOfPlugins(obj)
            shared_plugins = obj.GetListOfSharedPlugins;
            app_plugins = obj.GetListOfAppPlugins;
            plugin_name_list = horzcat(shared_plugins, app_plugins);
        end
        
        function plugin_name_list = GetListOfSharedPlugins(obj)
            plugin_name_list = CoreDiskUtilities.GetAllMatlabFilesInFolders(obj.GetListOfSharedPluginFolders);
        end
        
        function plugin_folders = GetListOfSharedPluginFolders(obj)
            plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(obj.GetSharedPluginsPath);
        end
        
        function plugin_name_list = GetListOfAppPlugins(obj)
            plugin_name_list = CoreDiskUtilities.GetAllMatlabFilesInFolders(obj.GetListOfAppPluginFolders);
        end
        
        function plugin_folders = GetListOfAppPluginFolders(obj)
            plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(obj.AppDef.GetPluginsPath);
        end
        
        function plugin_name_list = GetListOfUserPlugins(obj)
            plugin_name_list = CoreDiskUtilities.GetAllMatlabFilesInFolders(obj.GetListOfUserPluginFolders);
        end
        
        function plugin_folders = GetListOfUserPluginFolders(obj)
            plugin_folders = CoreDiskUtilities.GetRecursiveListOfDirectories(obj.AppDef.GetUserPluginsPath);
        end
        
        function plugins_path = GetSharedPluginsPath(~)
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', PTKSoftwareInfo.SharedPluginDirectoryName);
        end        
    end
end