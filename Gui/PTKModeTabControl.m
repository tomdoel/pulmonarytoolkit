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
        Gui
        
        FilePanel
        ViewPanel
        PluginsPanel
        EditPanel
        AnalysisPanel
        
        TabEnabled
    end

    methods
        function obj = PTKModeTabControl(parent, organised_plugins, reporting)
            obj = obj@PTKTabControl(parent, reporting);

            obj.OrganisedPlugins = organised_plugins;
            obj.TabEnabled = containers.Map;

            obj.Gui = parent;
            
            obj.LeftBorder = true;

            obj.FilePanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'File', 'all', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Reporting);
            obj.AddTabbedPanel(obj.FilePanel, 'File', 'file', 'Import data');
            obj.FilePanel.AddPlugins([]);
            
            obj.PluginsPanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'Home', 'all', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Reporting);
            obj.AddTabbedPanel(obj.PluginsPanel, 'Segment', 'segment', 'Algorithms for segmenting lung features');
            obj.PluginsPanel.AddPlugins([]);

            obj.ViewPanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'View', 'all', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Reporting);
            obj.AddTabbedPanel(obj.ViewPanel, 'View', 'view', 'Visualisation');
            obj.ViewPanel.AddPlugins([]);
            
            obj.EditPanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'Edit', PTKModes.EditMode, @obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Reporting);
            obj.AddTabbedPanel(obj.EditPanel, 'Correct', 'edit', 'Manual correction of results');
            obj.EditPanel.AddPlugins([]);
            
            obj.AnalysisPanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'Analysis', 'all', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Reporting);
            obj.AddTabbedPanel(obj.AnalysisPanel, 'Analyse', 'analysis', 'Perform analysis and save as tables and graphs');
            obj.AnalysisPanel.AddPlugins([]);
        end
        
        function mode = GetPluginMode(obj, mode_tag)
            panel = obj.PanelMap(mode_tag);
            mode = panel.GetMode;
        end
        
        function AddPreviewImage(obj, plugin_name, dataset, window, level)
            for panel = obj.PanelMap.values
                panel{1}.AddPreviewImage(plugin_name, dataset, window, level);
            end
        end
        
        function RefreshPlugins(obj, dataset, window, level)
            obj.OrganisedPlugins.Repopulate(obj.Reporting)
            for panel = obj.PanelMap.values
                panel{1}.RefreshPlugins(dataset, window, level);
            end
        end
        
        function AddAllPreviewImagesToButtons(obj, dataset, window, level)
            for panel = obj.PanelMap.values
                panel{1}.AddAllPreviewImagesToButtons(dataset, window, level);
            end
        end
        
        function ForceEnableAllTabs(obj)
            for panel_key = obj.PanelMap.keys
                obj.TabPanel.EnableTab(panel_key{1});
            end
        end
        
        function UpdateDynamicPanels(obj)
        end
        
        function UpdateMode(obj, plugin_info)
            force_change = false;
            first_enabled_tab = [];
            for panel_key = obj.PanelMap.keys
                panel = obj.PanelMap(panel_key{1});
                panel_mode_name = panel.GetMode;
                if strcmp(panel_mode_name, 'all')
                    if isempty(first_enabled_tab)
                        first_enabled_tab = panel_key{1};
                    end
                else
                    if isempty(plugin_info) || ~any(strcmp(panel_mode_name, plugin_info.EnableModes))
                        obj.TabPanel.DisableTab(panel_key{1});
                        if strcmp(panel_key{1}, obj.CurrentPanelTag)
                            force_change = true;
                        end
                    else
                        obj.TabPanel.EnableTab(panel_key{1});
                        if isempty(first_enabled_tab)
                            first_enabled_tab = panel_key{1};
                        end
                    end
                end
            end
            if force_change && ~isempty(first_enabled_tab)
                obj.ChangeSelectedTab(first_enabled_tab);
            end
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