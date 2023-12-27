classdef MimPluginsPanel < GemCompositePanel
    % MimPluginsPanel. Part of the gui for the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the TD MIM Toolkit.
    %
    %     MimPluginsPanel builds and manages the panel of plugins and gui plugins
    %     as part of the TD MIM Toolkit gui.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        
        % Plugin information grouped by category
        PluginsByCategory
        
        % The plugin panels for each category
        PluginPanels

        % Callbacks for when plugin buttons are clicked
        RunPluginCallback
        RunGuiPluginCallback
        LoadManualSegmentationCallback
        
        OrganisedPlugins
        ModeToSwitchTo
        ModeTabName
        Visibility
        
        PreviewFetcher
    end
    
    methods
        function obj = MimPluginsPanel(parent, organised_plugins, plugins_mode_group, mode_to_switch_to, visibility, run_plugin_callback, run_gui_plugin_callback, load_segmentation_callback, preview_fetcher)
            obj = obj@GemCompositePanel(parent);
            
            obj.PreviewFetcher = preview_fetcher;
            
            obj.OrganisedPlugins = organised_plugins;
            obj.ModeTabName = plugins_mode_group;
            obj.ModeToSwitchTo = mode_to_switch_to;
            obj.Visibility = visibility;
            
            obj.TopMargin = 5;
            obj.BottomMargin = 5;
            obj.VerticalSpacing = 10;
            obj.LeftMargin = 5;
            obj.RightMargin = 5;
            
            obj.PluginPanels = containers.Map();
            
            obj.RunPluginCallback = run_plugin_callback;
            obj.RunGuiPluginCallback = run_gui_plugin_callback;
            obj.LoadManualSegmentationCallback = load_segmentation_callback;
        end        

        function UpdateForNewImage(obj, preview_fetcher, window, level)
            % Causes each plugin panel to refresh the preview images for every button using
            % the supplied dataset
            
            for panel = obj.PluginPanels.values
                panel{1}.UpdateForNewImage(preview_fetcher, window, level);
            end            
        end
        
        function AddPreviewImage(obj, plugin_name, preview_fetcher, window, level)
            % Updates the image for one plugin
            
            for panel = obj.PluginPanels.values
                if panel{1}.AddPreviewImage(plugin_name, preview_fetcher, window, level);
                    return;
                end
            end
        end

        function AddPlugins(obj, current_dataset)
            % This function adds buttons for all files in the Plugins directory

            plugins_by_category = obj.OrganisedPlugins.GetAllPluginsForMode(obj.ModeTabName);
            
            obj.PluginsByCategory = plugins_by_category;
            obj.AddPluginCategoryPanels(plugins_by_category);
        end

        function RefreshPlugins(obj, current_dataset, window, level)
            % Remove and re-add all plugins, so we detect plugins which have been added or
            % removed
            
            obj.RemoveAllPanels;
            obj.AddPlugins(current_dataset)
            
            % We need to resize here because the position of the new panels is not valid
            if ~isempty(obj.Position)
                obj.Resize(obj.Position);
            end
            obj.UpdateForNewImage(obj.PreviewFetcher, window, level);
        end        

        function visibility = GetVisibility(obj)
            visibility = obj.Visibility;
        end

        function mode = GetModeTabName(obj)
            mode = obj.ModeTabName;
        end
        
        function mode = GetModeToSwitchTo(obj)
            mode = obj.ModeToSwitchTo;
        end
    end
    
    
    methods (Access = private)

        function AddPluginCategoryPanels(obj, plugins_by_category)
            % Add panels for each plugin category
            
            obj.PluginPanels = containers.Map();
            
            for category = plugins_by_category.keys
                current_category_map = plugins_by_category(char(category));
                new_panel_handle = MimPluginGroupPanel(obj, category, current_category_map, obj.LoadManualSegmentationCallback);
                obj.PluginPanels(char(category)) = new_panel_handle;
                obj.AddPanel(new_panel_handle);
            end
        end

    end
end