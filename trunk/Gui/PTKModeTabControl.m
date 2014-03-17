classdef PTKModeTabControl < PTKTabControl
    % PTKModeTabControl. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (Access = private)
        OrganisedPlugins
        Settings
        Gui
        
        FilePanel
        ViewPanel
        PluginsPanel
        EditPanel
        AnalysisPanel
        
        TabEnabled
    end

    methods
        function obj = PTKModeTabControl(parent, settings, reporting)
            obj = obj@PTKTabControl(parent, reporting);
            
            obj.Settings = settings;
            
            obj.OrganisedPlugins = PTKOrganisedPlugins(settings, reporting);
            obj.TabEnabled = containers.Map;
            
            obj.Gui = parent;

            obj.FilePanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'File', 'all', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Reporting);
            obj.AddTab(obj.FilePanel, 'File', 'file', 'Import data');
            obj.FilePanel.AddPlugins([]);
            
            obj.PluginsPanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'Home', 'all', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Reporting);
            obj.AddTab(obj.PluginsPanel, 'Segment', 'segment', 'Algorithms for segmenting lung features');
            obj.PluginsPanel.AddPlugins([]);

            obj.ViewPanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'View', 'all', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Reporting);
            obj.AddTab(obj.ViewPanel, 'View', 'view', 'Visualisation');
            obj.ViewPanel.AddPlugins([]);
            
            obj.EditPanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'Edit', PTKModes.EditMode, @obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Reporting);
            obj.AddTab(obj.EditPanel, 'Correct', 'edit', 'Manual correction of results');
            obj.EditPanel.AddPlugins([]);
            
            obj.AnalysisPanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'Analysis', 'all', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Reporting);
            obj.AddTab(obj.AnalysisPanel, 'Analyse', 'analysis', 'Perform analysis and save as tables and graphs');
            obj.AnalysisPanel.AddPlugins([]);
        end
        
        function mode = GetPluginMode(obj, mode_tag)
            tag = obj.TabMap(mode_tag);
            mode = tag.GetMode;
        end
        
        function AddPreviewImage(obj, plugin_name, dataset, window, level)
            for tab = obj.TabMap.values
                tab{1}.AddPreviewImage(plugin_name, dataset, window, level);
            end
        end
        
        function RefreshPlugins(obj, dataset, window, level)
            obj.OrganisedPlugins.Repopulate(obj.Settings, obj.Reporting)
            for tab = obj.TabMap.values
                tab{1}.RefreshPlugins(dataset, window, level);
            end
        end
        
        function AddAllPreviewImagesToButtons(obj, dataset, window, level)
            for tab = obj.TabMap.values
                tab{1}.AddAllPreviewImagesToButtons(dataset, window, level);
            end
        end
        
        function ForceEnableAllTabs(obj)
            for tab_key = obj.TabMap.keys
                obj.TabPanel.EnableTab(tab_key{1});
            end
        end
        
        function UpdateMode(obj, plugin_info)
            force_change = false;
            first_enabled_tab = [];
            for tab_key = obj.TabMap.keys
                tab = obj.TabMap(tab_key{1});
                tab_mode_name = tab.GetMode;
                if strcmp(tab_mode_name, 'all')
                    if isempty(first_enabled_tab)
                        first_enabled_tab = tab_key{1};
                    end
                else
                    if isempty(plugin_info) || ~any(strcmp(tab_mode_name, plugin_info.EnableModes))
                        obj.TabPanel.DisableTab(tab_key{1});
                        if strcmp(tab_key{1}, obj.CurrentPanelTag)
                            force_change = true;
                        end
                    else
                        obj.TabPanel.EnableTab(tab_key{1});
                        if isempty(first_enabled_tab)
                            first_enabled_tab = tab_key{1};
                        end
                    end
                end
            end
            if force_change && ~isempty(first_enabled_tab)
                obj.ChangeSelectedTab(first_enabled_tab);
            end
        end
        
        function Resize(obj, panel_position)
            Resize@PTKTabControl(obj, panel_position);
        end
    end
    
    methods (Access = private)
        
        function RunPluginCallback(obj, plugin_name)
            obj.Gui.RunPluginCallback(plugin_name);
        end
        
        function RunGuiPluginCallback(obj, plugin_name)
            obj.Gui.RunGuiPluginCallback(plugin_name);
        end
        
    end
end