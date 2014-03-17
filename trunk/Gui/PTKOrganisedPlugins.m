classdef PTKOrganisedPlugins < handle
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
        Modes
        GuiModes
    end
    
    methods
        function obj = PTKOrganisedPlugins(settings, reporting)
            obj.Repopulate(settings, reporting);
        end
        
        function Repopulate(obj, settings, reporting)
            obj.Modes = containers.Map;
            obj.GuiModes = containers.Map;
            plugin_list = obj.GetListOfPossiblePluginNames;
            for plugin_filename = plugin_list
                plugin_name = plugin_filename{1}.First;
                obj.AddPluginFromName(plugin_name, plugin_filename, false, settings, reporting);
            end
            gui_plugin_list = obj.GetListOfPossibleGuiPluginNames;
            for plugin_filename = gui_plugin_list
                plugin_name = plugin_filename{1}.First;
                obj.AddPluginFromName(plugin_name, plugin_filename, true, settings, reporting);
            end
        end
        
        function plugin_list = GetPluginsForMode(obj, mode)
            if obj.Modes.isKey(mode)
                plugin_list = obj.Modes(mode);
            else
                plugin_list = containers.Map;
            end
        end
        
        function plugin_list = GetGuiPluginsForMode(obj, mode)
            if obj.GuiModes.isKey(mode)
                plugin_list = obj.GuiModes(mode);
            else
                plugin_list = containers.Map;
            end
        end
    end
    
    methods (Access = private)
        function AddPluginFromName(obj, plugin_name, plugin_filename, is_gui_plugin, settings, reporting)
            try
                if (exist(plugin_name, 'class') == 8)
                    plugin_handle = str2func(plugin_name);
                    plugin_class_object = feval(plugin_handle);
                    if isa(plugin_class_object, 'PTKPlugin') || isa(plugin_class_object, 'PTKGuiPlugin')
                        
                        hide_plugin = plugin_class_object.HidePluginInDisplay || (~settings.DeveloperMode && isprop(plugin_class_object, 'Visibility') && strcmp(plugin_class_object.Visibility, 'Developer'));
                        
                        if ~hide_plugin
                            obj.AddPluginClass(plugin_class_object, plugin_name, is_gui_plugin, plugin_filename, reporting)
                        end
                    else
                        reporting.ShowWarning('PTKOrganisedPlugins:FileNotPlugin', ['The file ' plugin_name ' was found in the Plugins directory but does not appear to be a PTKPlugin class. I am ignoring this file. If this is not a PTKPlugin class, you should remove thie file from the Plugins folder; otherwise check the file for errors.'], []);
                    end
                else
                    reporting.ShowWarning('PTKOrganisedPlugins:FileNotPlugin', ['The file ' plugin_name ' was found in the Plugins directory but does not appear to be a PTKPlugin class. I am ignoring this file. If this is not a PTKPlugin class, you should remove thie file from the Plugins folder; otherwise check the file for errors.'], []);
                end
            catch ex
                reporting.ShowWarning('PTKOrganisedPlugins:ParsePluginError', ['The file ' plugin_name ' was found in the Plugins directory but does not appear to be a PTKPlugin class, or contains errors. I am ignoring this file. If this is not a PTKPlugin class, you should remove thie file from the Plugins folder; otherwise check the file for errors.'], ex.message);
            end
        end
        
        function AddPluginClass(obj, plugin_class_object, plugin_name, is_gui_plugin, plugin_filename, reporting)
            
            % get information from the plugin
            % Parse the class properties into a data structure
            if is_gui_plugin
                new_plugin = PTKParseGuiPluginClass(plugin_name, plugin_class_object, reporting);
            else
                new_plugin = PTKParsePluginClass(plugin_name, plugin_class_object, reporting);
            end

            if isempty(new_plugin.Mode)
                new_plugin.Mode = 'Home';
            end
            
            if isempty(new_plugin.Category)
                if ~isempty(plugin_filename{1}.Second)
                    new_plugin.Category = plugin_filename{1}.Second;
                else
                    new_plugin.Category = PTKSoftwareInfo.DefaultCategoryName;
                end
            end
            
            obj.Add(plugin_name, new_plugin.Mode, new_plugin.Category, new_plugin, is_gui_plugin);
        end
        
        function Add(obj, name, mode, category, new_plugin, is_gui_plugin)
            if is_gui_plugin
                if obj.GuiModes.isKey(mode)
                    mode_map = obj.GuiModes(mode);
                else
                    mode_map = containers.Map;
                end
            else
                if obj.Modes.isKey(mode)
                    mode_map = obj.Modes(mode);
                else
                    mode_map = containers.Map;
                end
            end
            
            if mode_map.isKey(category)
                category_map = mode_map(category);
            else
                category_map = containers.Map;
            end
            
            category_map(name) = new_plugin;
            
            mode_map(category) = category_map;
            
            if is_gui_plugin       
                obj.GuiModes(mode) = mode_map;
            else
                obj.Modes(mode) = mode_map;
            end
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