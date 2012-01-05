classdef TDGuiPluginInformation
    % TDGuiPluginInformation. Part of the gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %     Fetches information about any gui-level plugins for the Pulmonary 
    %     Toolkit which are available. Gui Plugins are stored in a subfolder of 
    %     the main application folder, and their properties are parsed to 
    %     categorise them for displaying in a GUI. Gui Plugins which do not 
    %     have the correct properties or have invalid property values are not 
    %     included in the lists returned.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods (Static)
        
        % Obtains a list of plugins found in the GuiPlugins folder        
        function plugin_list = GetListOfPlugins
            plugin_list = TDDiskUtilities.GetDirectoryFileList(TDGuiPluginInformation.GetPluginsPath, '*.m');
            user_plugin_list = TDDiskUtilities.GetDirectoryFileList(TDGuiPluginInformation.GetUserPluginsPath, '*.m');
            plugin_list = horzcat(plugin_list, user_plugin_list);
        end
        
        % Obtains a list of gui plugins and sorts into categories according to
        % their properties
        function plugins_by_category = GetPluginInformation
            plugin_list = TDGuiPluginInformation.GetListOfPlugins;
            
            plugins_by_category = containers.Map;
            
            for plugin_filename = plugin_list
                
                [~, plugin_name, ~] = fileparts(plugin_filename{1});
                
                try
                    % get information from the plugin
                    new_plugin = TDGuiPluginInformation.LoadPluginInfoStructure(plugin_name);
                    
                    if ~new_plugin.HidePluginInDisplay
                        
                        
                        % Add plugin to the plugin map for its particular category
                        if ~plugins_by_category.isKey(new_plugin.Category)
                            plugins_by_category(new_plugin.Category) = containers.Map;
                        end
                        current_category_map = plugins_by_category(new_plugin.Category);
                        current_category_map(new_plugin.PluginName) = new_plugin;
                        plugins_by_category(new_plugin.Category) = current_category_map;
                    end
                    
                catch
                    disp(['Warning: file ' plugin_name ' found in GuiPlugins directory did not return the correct information structure when called with no arguments.']);
                end
            end
        end
        
        % Obtains a handle to the gui plugin which can be used to parse its properties
        function new_plugin = LoadPluginInfoStructure(plugin_name)
            plugin_handle = str2func(plugin_name);
            plugin_info_structure = feval(plugin_handle);
            new_plugin = TDGuiPluginInformation.ParsePluginClass(plugin_name, plugin_info_structure);            
        end
    end
    
    methods (Access = private, Static)
        
        function plugins_path = GetPluginsPath
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', TDSoftwareInfo.GuiPluginDirectoryName);
        end
        
        function plugins_path = GetUserPluginsPath
            full_path = mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            plugins_path = fullfile(path_root, '..', TDSoftwareInfo.UserDirectoryName, TDSoftwareInfo.GuiPluginDirectoryName);
        end
        
        function new_plugin = ParsePluginClass(plugin_name, plugin_class)
            new_plugin = [];
            new_plugin.PluginName = plugin_name;
            
            if plugin_class.TDPTKVersion ~= '1'
                disp(['Warning: plugin ' plugin_name ' was created for a more recent version of this software']);
            end
            
            new_plugin.ToolTip = plugin_class.ToolTip;
            new_plugin.ButtonText = plugin_class.ButtonText;
            new_plugin.Category = plugin_class.Category;
            new_plugin.HidePluginInDisplay = plugin_class.HidePluginInDisplay;
            new_plugin.ButtonWidth = plugin_class.ButtonWidth;
            new_plugin.ButtonHeight = plugin_class.ButtonHeight;
            new_plugin.AlwaysRunPlugin = false; % Ensures plugin name is not in italics
        end
        
    end    
end