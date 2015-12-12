classdef PTKModeTabControl < GemTabControl
    % PTKModeTabControl. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (Access = private)
        OrganisedPlugins
        OrganisedManualSegmentations
        Gui
        
        SegmentPanel
        PluginsPanel
        EditPanel
        ManualSegmentationPanel
        AnalysisPanel
        
        TabEnabled
    end

    methods
        function obj = PTKModeTabControl(parent, organised_plugins, organised_manual_segmentations, app_def)
            obj = obj@GemTabControl(parent);

            obj.OrganisedPlugins = organised_plugins;
            obj.OrganisedManualSegmentations = organised_manual_segmentations;
            obj.TabEnabled = containers.Map;

            obj.Gui = parent;
            
            obj.LeftBorder = true;

            obj.SegmentPanel = PTKToolbarPanel(obj, obj.OrganisedPlugins, 'Segment', [], 'Dataset', obj.Gui, app_def, true);
            obj.AddTabbedPanel(obj.SegmentPanel, 'Segment', 'Segment', 'Segmentation');
            
            obj.EditPanel = PTKToolbarPanel(obj, obj.OrganisedPlugins, 'Edit', PTKModes.EditMode, 'Plugin', obj.Gui, app_def, true);
            obj.AddTabbedPanel(obj.EditPanel, 'Correct', 'Edit', 'Manual correction of results');

            obj.ManualSegmentationPanel = PTKPluginsSlidingPanel(obj, organised_manual_segmentations, 'ManualSegmentation', PTKModes.ManualSegmentationMode, 'Dataset', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, @obj.LoadSegmentationCallback);
            obj.AddTabbedPanel(obj.ManualSegmentationPanel, 'Manual Segmentation', 'ManualSegmentation', 'Manual segmentation');
            obj.ManualSegmentationPanel.AddPlugins([]);
            
            obj.AnalysisPanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'Analysis', [], 'Dataset', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, @obj.LoadSegmentationCallback);
            obj.AddTabbedPanel(obj.AnalysisPanel, 'Analyse', 'Analysis', 'Perform analysis and save as tables and graphs');
            obj.AnalysisPanel.AddPlugins([]);

            obj.PluginsPanel = PTKPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'Plugins', [], 'Dataset', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, @obj.LoadSegmentationCallback);
            obj.AddTabbedPanel(obj.PluginsPanel, 'Plugins', 'Plugins', 'Algorithms for segmenting lung features');
            obj.PluginsPanel.AddPlugins([]);
        end
        
        function mode = GetModeToSwitchTo(obj, mode_tag)
            panel = obj.PanelMap(mode_tag);
            mode = panel.GetModeToSwitchTo;
        end
        
        function AddPreviewImage(obj, plugin_name, dataset, window, level)
            for panel = obj.PanelMap.values
                panel{1}.AddPreviewImage(plugin_name, dataset, window, level);
            end
        end
        
        function RefreshPlugins(obj, dataset, window, level)
            obj.OrganisedPlugins.Repopulate(obj.Reporting);
            obj.OrganisedManualSegmentations.Repopulate(obj.Reporting);
            for panel = obj.PanelMap.values
                panel{1}.RefreshPlugins(dataset, window, level);
            end
        end
        
        function UpdateGuiForNewDataset(obj, dataset, window, level)
            % Update manual segmentations
            obj.OrganisedManualSegmentations.Repopulate(obj.Reporting);
            obj.ManualSegmentationPanel.RefreshPlugins(dataset, window, level);
            % Add preview images to buttons
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
            obj.SegmentPanel.Update(obj.Gui);
            obj.EditPanel.Update(obj.Gui);
        end
        
        function UpdateMode(obj, plugin_info)
            force_change = false;
            first_enabled_tab = [];
            for panel_key = obj.PanelMap.keys
                panel = obj.PanelMap(panel_key{1});
                visibility = panel.GetVisibility;
                if isempty(visibility) || strcmp(visibility, 'Always')
                    if isempty(first_enabled_tab)
                        first_enabled_tab = panel_key{1};
                    end
                elseif strcmp(visibility, 'Dataset')
                    if obj.Gui.IsDatasetLoaded
                        obj.TabPanel.EnableTab(panel_key{1});
                        if isempty(first_enabled_tab)
                            first_enabled_tab = panel_key{1};
                        end
                    else
                        obj.TabPanel.DisableTab(panel_key{1});
                        if strcmp(panel_key{1}, obj.CurrentPanelTag)
                            force_change = true;
                        end
                    end
                elseif strcmp(visibility, 'Plugin')
                    panel_mode_name = panel.GetModeTabName;
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
                else
                    obj.Reporting.Error('PTKModeTabControl:UnknownModeVisibility', 'The Visibility property of the mode panel is set to an unknown value');
                end
            end
            if force_change && ~isempty(first_enabled_tab)
                obj.ChangeSelectedTab(first_enabled_tab);
            end
        end
        
        function AutoTabSelection(obj, mode)
            if ~isempty(mode)
            tab_to_select = [];
            for panel_key = obj.PanelMap.keys
                panel = obj.PanelMap(panel_key{1});
                if isempty(tab_to_select) && obj.TabPanel.IsTabEnabled(panel_key{1})
                    tab_to_select = panel_key{1};
                end                
                mode_to_switch_to = panel.GetModeToSwitchTo;
                if ~isempty(mode) && strcmp(mode, mode_to_switch_to)
                    tab_to_select = mode;
                end
            end
            if ~isempty(tab_to_select)
                obj.ChangeSelectedTab(tab_to_select);
            end
            end
        end
        
        function enabled = IsTabEnabled(obj, panel_mode_name)
            enabled = obj.TabPanel.IsTabEnabled(panel_mode_name);
        end        
    end
    
    methods (Access = private)
        
        function RunPluginCallback(obj, plugin_name)
            obj.Gui.RunPluginCallback(plugin_name);
        end
        
        function RunGuiPluginCallback(obj, plugin_name)
            obj.Gui.RunGuiPluginCallback(plugin_name);
        end
        
        function LoadSegmentationCallback(obj, plugin_name)
            obj.Gui.LoadSegmentationCallback(plugin_name);
        end
    end
end