classdef MimPluginsSlidingPanel < GemSlidingPanel
    % MimPluginsSlidingPanel. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimPluginsSlidingPanel represents the panel underneath the
    %     MimPluginsPanel, which allows the panel to be scrolled using a
    %     scrollbar and swipe gestures.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    methods
        function obj = MimPluginsSlidingPanel(parent, organised_plugins, plugins_mode_group, mode_name, enabled_flag, run_plugin_callback, run_gui_plugin_callback, load_segmentation_callback, preview_fetcher)
            obj = obj@GemSlidingPanel(parent);
            obj.FloatingPanel = MimPluginsPanel(obj, organised_plugins, plugins_mode_group, mode_name, enabled_flag, run_plugin_callback, run_gui_plugin_callback, load_segmentation_callback, preview_fetcher);
            obj.AddChild(obj.FloatingPanel);
        end
        
        function AddPlugins(obj, current_dataset)
            obj.FloatingPanel.AddPlugins(current_dataset); 
        end
        
        function UpdateForNewImage(obj, preview_fetcher, window, level)
            obj.FloatingPanel.UpdateForNewImage(preview_fetcher, window, level)
        end
        
        function AddPreviewImage(obj, plugin_name, preview_fetcher, window, level)
            obj.FloatingPanel.AddPreviewImage(plugin_name, preview_fetcher, window, level)
        end

        function RefreshPlugins(obj, current_dataset, window, level)
            obj.FloatingPanel.RefreshPlugins(current_dataset, window, level)
        end
        
        function mode = GetModeTabName(obj)
            mode = obj.FloatingPanel.GetModeTabName;
        end

        function mode = GetVisibility(obj)
            mode = obj.FloatingPanel.GetVisibility;
        end
        
        function mode = GetModeToSwitchTo(obj)
            mode = obj.FloatingPanel.GetModeToSwitchTo;
        end
    end
end