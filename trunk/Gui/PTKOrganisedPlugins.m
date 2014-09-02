classdef PTKOrganisedPlugins < PTKBaseClass
    % PTKOrganisedPlugins. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        PluginGroups
        GuiApp
        OrganisedPluginsModeList
    end
    
    methods
        function obj = PTKOrganisedPlugins(gui_app, reporting)
            obj.GuiApp = gui_app;
            obj.OrganisedPluginsModeList = PTKOrganisedPluginsModeList;
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
            locations = PTKContainerUtilities.GetMatrixOfFieldValuesFromSet(tool_list, 'Location');
            [~, index] = sort(locations, 'ascend');
            tool_list = tool_list(index);
        end        
    end    
    
    methods (Static, Access = private)
        
        function combined_plugin_list = GetListOfPossiblePluginNames
            % Obtains a list of plugins found in the Plugins folder
            plugin_list = PTKDirectories.GetListOfPlugins;
            if PTKSoftwareInfo.DemoMode
                combined_plugin_list = plugin_list;
            else
                user_plugin_list = PTKDirectories.GetListOfUserPlugins;
                combined_plugin_list = horzcat(plugin_list, user_plugin_list);
            end
        end
        
        function combined_plugin_list = GetListOfPossibleGuiPluginNames
            % Obtains a list of Gui plugins found in the GuiPlugins folder
            plugin_list = PTKDirectories.GetListOfGuiPlugins;
            if PTKSoftwareInfo.DemoMode
                combined_plugin_list = plugin_list;
            else
                user_plugin_list = PTKDirectories.GetListOfUserGuiPlugins;
                combined_plugin_list = horzcat(plugin_list, user_plugin_list);
            end
        end
        
    end
end