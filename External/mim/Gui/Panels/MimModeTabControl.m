classdef MimModeTabControl < GemTabControl
    % MimModeTabControl. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    

    properties (Access = private)
        OrganisedPlugins
        OrganisedManualSegmentations
        Gui
        PreviewFetcher
        
        SegmentPanel
        PluginsPanel
        EditPanel
        AnalysisPanel
        MarkersPanel
        
        TabEnabled
    end

    methods
        function obj = MimModeTabControl(parent, preview_fetcher, organised_plugins, organised_manual_segmentations, marker_manager, gui_dataset_state, app_def)
            obj = obj@GemTabControl(parent);

            obj.PreviewFetcher = preview_fetcher;
            obj.OrganisedPlugins = organised_plugins;
            obj.OrganisedManualSegmentations = organised_manual_segmentations;
            obj.TabEnabled = containers.Map();

            obj.Gui = parent;
            
            obj.LeftBorder = true;

            obj.SegmentPanel = MimSegmentPanel(obj, obj.OrganisedPlugins, 'Segment', [], 'Dataset', obj.Gui, app_def, gui_dataset_state, true, true);
            obj.AddTabbedPanel(obj.SegmentPanel, 'Segment', 'Segment', 'Segmentation');
            
            obj.EditPanel = MimToolbarPanel(obj, obj.OrganisedPlugins, 'Edit', MimModes.EditMode, 'Plugin', obj.Gui, app_def, true, true);
            obj.AddTabbedPanel(obj.EditPanel, 'Correct', 'Edit', 'Manual correction of results');

            obj.MarkersPanel = MimMarkerPanel(obj, gui_dataset_state, marker_manager, obj.OrganisedPlugins, 'Markers', MimModes.MarkerMode, 'Dataset', obj.Gui, app_def, true, true);
            obj.AddTabbedPanel(obj.MarkersPanel, 'Markers', 'Markers', 'Create markers for validation');
            
            obj.AnalysisPanel = MimToolbarPanel(obj, obj.OrganisedPlugins, 'Analysis', [], 'Dataset', obj.Gui, app_def, true, true);
            obj.AddTabbedPanel(obj.AnalysisPanel, 'Analyse', 'Analysis', 'Perform analysis and save as tables and graphs');

            obj.PluginsPanel = MimPluginsSlidingPanel(obj, obj.OrganisedPlugins, 'Plugins', [], 'Developer', @obj.RunPluginCallback, @obj.RunGuiPluginCallback, @obj.LoadSegmentationCallback, preview_fetcher);
            obj.AddTabbedPanel(obj.PluginsPanel, 'Plugins', 'Plugins', 'Algorithms for segmenting features');
            obj.PluginsPanel.AddPlugins([]);
            
            obj.AddEventListener(gui_dataset_state, 'PreviewImageChanged', @obj.PreviewImageChangedCallback);
        end
        
        function mode = GetModeToSwitchTo(obj, mode_tag)
            if isempty(mode_tag)
                mode = [];
            else
                panel = obj.PanelMap(mode_tag);
                mode = panel.GetModeToSwitchTo;
            end
        end
        
        function PreviewImageChangedCallback(obj, ~, event_data)
            plugin_name = event_data.Data;
            obj.AddPreviewImage(plugin_name, obj.PreviewFetcher, obj.Gui.ImagePanel.Window, obj.Gui.ImagePanel.Level);
        end
        
        function AddPreviewImage(obj, plugin_name, preview_fetcher, window, level)
            for panel = obj.PanelMap.values
                panel{1}.AddPreviewImage(plugin_name, preview_fetcher, window, level);
            end
        end
        
        function RefreshPlugins(obj, dataset, window, level)
            obj.OrganisedPlugins.Repopulate(obj.Reporting);
            obj.OrganisedManualSegmentations.Repopulate(obj.Reporting);
            for panel = obj.PanelMap.values
                panel{1}.RefreshPlugins(dataset, window, level);
            end
        end
        
        function UpdateGuiForNewDataset(obj, preview_fetcher, window, level)
            % Update manual segmentations
            obj.OrganisedManualSegmentations.Repopulate(obj.Reporting);
            % Add preview images to buttons
            for panel = obj.PanelMap.values
                panel{1}.UpdateForNewImage(preview_fetcher, window, level);
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
            obj.MarkersPanel.Update(obj.Gui);
            obj.AnalysisPanel.Update(obj.Gui);
        end
        
        function UpdateMode(obj, state)
            plugin_info = state.CurrentPluginInfo;
            force_change = false;
            first_enabled_tab = [];
            for panel_key = obj.OrderedTags
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
                elseif strcmp(visibility, 'Developer')
                    if obj.Gui.DeveloperMode
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
                    
                    % Force edit tabs to be enabled when there is a manual
                    % segmentation. This could be done in a more elegant
                    % way!
                    manual_edit_override = isempty(plugin_info) && ~isempty(state.CurrentSegmentationName) && strcmp(panel_mode_name, MimModes.EditMode);
                    
                    if ~manual_edit_override && (isempty(plugin_info) || ~any(strcmp(panel_mode_name, plugin_info.EnableModes)))
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
                    obj.Reporting.Error('MimModeTabControl:UnknownModeVisibility', 'The Visibility property of the mode panel is set to an unknown value');
                end
            end
            if isempty(first_enabled_tab) && ~isempty(obj.CurrentPanelTag)
                obj.ChangeSelectedTab(first_enabled_tab);
            end
            if force_change && ~isempty(first_enabled_tab)
                obj.ChangeSelectedTab(first_enabled_tab);
            end
        end
        
        function AutoTabSelection(obj, mode)
            if ~isempty(mode)
            tab_to_select = [];
            for panel_key = obj.OrderedTags
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