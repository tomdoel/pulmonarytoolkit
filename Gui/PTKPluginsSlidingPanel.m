classdef PTKPluginsSlidingPanel < PTKSlidingPanel
    % PTKPluginsSlidingPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPluginsSlidingPanel represents the panel underneath the
    %     PTKPluginsPanel, which allows the panel to be scrolled using a
    %     scrollbar and swipe gestures.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods
        function obj = PTKPluginsSlidingPanel(parent, organised_plugins, mode_name, plugin_mode_name, run_plugin_callback, run_gui_plugin_callback, reporting)
            obj = obj@PTKSlidingPanel(parent, reporting);
            obj.FloatingPanel = PTKPluginsPanel(obj, organised_plugins, mode_name, plugin_mode_name, run_plugin_callback, run_gui_plugin_callback, reporting);
            obj.AddChild(obj.FloatingPanel);
        end
        
        function AddPlugins(obj, current_dataset)
            obj.FloatingPanel.AddPlugins(current_dataset); 
        end
        
        function AddAllPreviewImagesToButtons(obj, current_dataset, window, level)
            obj.FloatingPanel.AddAllPreviewImagesToButtons(current_dataset, window, level)
        end
        
        function AddPreviewImage(obj, plugin_name, current_dataset, window, level)
            obj.FloatingPanel.AddPreviewImage(plugin_name, current_dataset, window, level)
        end

        function RefreshPlugins(obj, current_dataset, window, level)
            obj.FloatingPanel.RefreshPlugins(current_dataset, window, level)
        end
        
        function mode = GetMode(obj)
            mode = obj.FloatingPanel.PluginModeName;
        end

    end
end