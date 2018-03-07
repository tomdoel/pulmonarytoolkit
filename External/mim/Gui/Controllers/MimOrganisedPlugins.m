classdef MimOrganisedPlugins < CoreBaseClass
    % MimOrganisedPlugins. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
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
            obj.OrganisedPluginsModeList = MimOrganisedPluginsModeList(app_def, plugin_cache);
            obj.Repopulate(reporting);
        end
        
        function Repopulate(obj, reporting)
            obj.OrganisedPluginsModeList.Clear;
            plugin_list = obj.GetListOfPossiblePluginNames();
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
        function plugin_name_list = GetListOfPossibleGuiPluginNames(obj)
            % Obtains a list of all Gui plugins available for this app
            
            plugin_name_list = {};
            plugins_folders = obj.AppDef.GetListOfGuiPluginsFolders;
            for folder = plugins_folders
                plugin_names = CoreDiskUtilities.GetAllMatlabFilesInFolders(CoreDiskUtilities.GetRecursiveListOfDirectories(folder{1}));
                plugin_name_list = horzcat(plugin_name_list, plugin_names);
            end
        end
        
        function plugin_name_list = GetListOfPossiblePluginNames(obj)
            % Obtains a list of all plugins available for this app
            
            plugin_name_list = {};
            plugins_folders = obj.AppDef.GetListOfPluginsFolders;
            for folder = plugins_folders
                plugin_names = CoreDiskUtilities.GetAllMatlabFilesInFolders(CoreDiskUtilities.GetRecursiveListOfDirectories(folder{1}));
                plugin_name_list = horzcat(plugin_name_list, plugin_names);
            end
        end
    end
end