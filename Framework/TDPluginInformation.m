classdef TDPluginInformation
    % TDPluginInformation. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Fetches information about any plugins for the Pulmonary Toolkit which
    %     are available. Plugins are stored in a subfolder of the main
    %     application folder, and their properties are parsed to categorise them
    %     for displaying in a GUI. Plugins which do not have the correct
    %     properties or have invalid property values are not included in the
    %     lists returned.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    methods (Static)
        
        % Obtains a list of plugins found in the Plugins folder
        function plugin_list = GetListOfPlugins(reporting)
            plugin_list = TDDiskUtilities.GetDirectoryFileList(TDPluginInformation.GetPluginsPath, '*.m');
            user_plugin_list = TDDiskUtilities.GetDirectoryFileList(TDPluginInformation.GetUserPluginsPath, '*.m');
            combined_plugin_list = horzcat(plugin_list, user_plugin_list);
            plugin_list = [];

            for plugin_filename = combined_plugin_list
                [~, plugin_name, ~] = fileparts(plugin_filename{1});
                try
                    if (exist(plugin_name, 'class') == 8)                    
                        plugin_handle = str2func(plugin_name);
                        plugin_info_structure = feval(plugin_handle);
                        if isa(plugin_info_structure, 'TDPlugin')
                            plugin_list{end + 1} = plugin_filename{1};
                        else
                            reporting.ShowWarning('TDPluginInformation:FileNotPlugin', ['Warning: The file ' plugin_filename{1} ' was found in the Plugins directory but does not appear to be a TDPlugin class. I am ignoring this file. If this is not a TDPlugin class, you should remove thie file from the Plugins folder; otherwise check the file for errors.'], []);
                        end
                    else
                        reporting.ShowWarning('TDPluginInformation:FileNotPlugin', ['Warning: The file ' plugin_filename{1} ' was found in the Plugins directory but does not appear to be a TDPlugin class. I am ignoring this file. If this is not a TDPlugin class, you should remove thie file from the Plugins folder; otherwise check the file for errors.'], []);
                    end
                catch ex
                    reporting.ShowWarning('TDPluginInformation:ParsePluginError', ['Warning: The file ' plugin_filename{1} ' was found in the Plugins directory but does not appear to be a TDPlugin class, or contains errors. I am ignoring this file. If this is not a TDPlugin class, you should remove thie file from the Plugins folder; otherwise check the file for errors.'], ex.message);
                end
            end            
        end
        
        % Obtains a list of plugins and sorts into categories according to their
        % properties
        function plugins_by_category = GetPluginInformation(reporting)
            plugin_list = TDPluginInformation.GetListOfPlugins(reporting);
            
            plugins_by_category = containers.Map;
            
            for plugin_filename = plugin_list
                
                [~, plugin_name, ~] = fileparts(plugin_filename{1});
                
                try
                    % get information from the plugin
                    new_plugin = TDPluginInformation.LoadPluginInfoStructure(plugin_name, reporting);
                    
                    if ~new_plugin.HidePluginInDisplay
                        
                        % Add plugin to the plugin map for its particular category
                        if ~plugins_by_category.isKey(new_plugin.Category)
                            plugins_by_category(new_plugin.Category) = containers.Map;
                        end
                        current_category_map = plugins_by_category(new_plugin.Category);
                        current_category_map(new_plugin.PluginName) = new_plugin;
                        plugins_by_category(new_plugin.Category) = current_category_map;
                    end
                    
                catch ex
                    reporting.ShowWarning('TDPluginInformation:PluginParseError', ['Warning: There is a problem with plugin file ' plugin_name '. Check there are no code errors and it has the correct properties.'], ex.message);
                end
            end
        end
        
        % Obtains a handle to the plugin which can be used to parse its properties
        function new_plugin = LoadPluginInfoStructure(plugin_name, reporting)
            plugin_handle = str2func(plugin_name);
            plugin_info_structure = feval(plugin_handle);
            
            % Parse the class properties into a data structure
            new_plugin = TDPluginInformation.ParsePluginClass(plugin_name, plugin_info_structure, reporting); 
        end
    end
    
    methods (Access = private, Static)
        
        function plugins_path = GetPluginsPath
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', TDSoftwareInfo.PluginDirectoryName);
        end
        
        function plugins_path = GetUserPluginsPath
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', TDSoftwareInfo.UserDirectoryName, TDSoftwareInfo.PluginDirectoryName);
        end
        
        function new_plugin = ParsePluginClass(plugin_name, plugin_class, reporting)
            new_plugin = [];
            new_plugin.PluginName = plugin_name;
            
            if ~strcmp(plugin_class.TDPTKVersion, TDSoftwareInfo.TDPTKVersion)
                reporting.ShowWarning('TDPluginInformation:MismatchingPluginVersion', ['Warning: plugin ' plugin_name ' was created for a more recent version of this software'], []);
            end
            
            new_plugin.ToolTip = plugin_class.ToolTip;
            new_plugin.AlwaysRunPlugin = plugin_class.AlwaysRunPlugin;
            new_plugin.AllowResultsToBeCached = plugin_class.AllowResultsToBeCached;
            new_plugin.PluginType = plugin_class.PluginType;
            new_plugin.ButtonText = plugin_class.ButtonText;
            new_plugin.Category = plugin_class.Category;
            new_plugin.HidePluginInDisplay = plugin_class.HidePluginInDisplay;
            new_plugin.ButtonWidth = plugin_class.ButtonWidth;
            new_plugin.ButtonHeight = plugin_class.ButtonHeight;
        end
        
    end    
end

