classdef PTKGuiPluginInformation
    % PTKGuiPluginInformation. Part of the gui for the Pulmonary Toolkit.
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
        function plugin_list = GetListOfPlugins(reporting)
            plugin_list = PTKDirectories.GetListOfGuiPlugins;
            
            if PTKSoftwareInfo.DemoMode
                combined_plugin_list = plugin_list;
            else
                user_plugin_list = PTKDirectories.GetListOfUserGuiPlugins;
                combined_plugin_list = horzcat(plugin_list, user_plugin_list);
            end
            plugin_list = [];

            for plugin_filename = combined_plugin_list
                plugin_name = plugin_filename{1}.First;
                try
                    if (exist(plugin_name, 'class') == 8)
                        plugin_handle = str2func(plugin_name);
                        plugin_info_structure = feval(plugin_handle);
                        if isa(plugin_info_structure, 'PTKGuiPlugin')
                            plugin_list{end + 1} = plugin_filename{1};
                        else
                            reporting.ShowWarning('PTKGuiPluginInformation:FileNotPlugin', ['The file ' plugin_name ' was found in the GuiPlugins directory but does not appear to be a PTKGuiPlugin class. I am ignoring this file. If this is not a PTKGuiPlugin class, you should remove thie file from the GuiPlugins folder; otherwise check the file for errors.'], []);
                        end
                    else
                        reporting.ShowWarning('PTKGuiPluginInformation:FileNotPlugin', ['The file ' plugin_name ' was found in the GuiPlugins directory but does not appear to be a PTKGuiPlugin class. I am ignoring this file. If this is not a PTKGuiPlugin class, you should remove thie file from the GuiPlugins folder; otherwise check the file for errors.'], []);
                    end
                catch ex
                    reporting.ShowWarning('PTKGuiPluginInformation:ParsePluginError', ['The file ' plugin_name ' was found in the GuiPlugins directory but does not appear to be a PTKGuiPlugin class, or contains errors. I am ignoring this file. If this is not a PTKGuiPlugin class, you should remove thie file from the GuiPlugins folder; otherwise check the file for errors.'], ex.message);
                end
            end
        end
        
        % Obtains a list of gui plugins and sorts into categories according to
        % their properties
        function plugins_by_category = GetPluginInformation(reporting)
            plugin_list = PTKGuiPluginInformation.GetListOfPlugins(reporting);
            
            plugins_by_category = containers.Map;
            
            for plugin_filename = plugin_list
                
                plugin_name = plugin_filename{1};
                
                try
                    % get information from the plugin
                    new_plugin = PTKGuiPluginInformation.LoadPluginInfoStructure(plugin_name.First, reporting);
                    if isempty(new_plugin.Category)
                        if ~isempty(plugin_filename{1}.Second)
                            new_plugin.Category = plugin_filename{1}.Second;
                        else
                            new_plugin.Category = PTKSoftwareInfo.DefaultCategoryName;
                        end
                        
                        new_plugin.Category = plugin_filename{1}.Second;
                    end
                    
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
                    reporting.ShowWarning('PTKGuiPluginInformation:InvalidGuiPlugin', ['The file ' plugin_name.First ' was found in GuiPlugins directory but does not appear to be a PTKGuiPlugin class, or contains errors.'], []);
                end
            end
        end
        
        % Obtains a handle to the gui plugin which can be used to parse its properties
        function new_plugin = LoadPluginInfoStructure(plugin_name, reporting)
            plugin_handle = str2func(plugin_name);
            plugin_info_structure = feval(plugin_handle);
            new_plugin = PTKGuiPluginInformation.ParsePluginClass(plugin_name, plugin_info_structure, reporting);
        end
    end
    
    methods (Access = private, Static)
        
        
        function new_plugin = ParsePluginClass(plugin_name, plugin_class, reporting)
            new_plugin = [];
            new_plugin.PluginName = plugin_name;
            
            new_plugin.ToolTip = plugin_class.ToolTip;
            new_plugin.ButtonText = plugin_class.ButtonText;
            if isprop(plugin_class, 'Category') && ~isempty(plugin_class.Category)
                new_plugin.Category = plugin_class.Category;
            else
                new_plugin.Category = [];
            end
            new_plugin.HidePluginInDisplay = plugin_class.HidePluginInDisplay;
            new_plugin.ButtonWidth = plugin_class.ButtonWidth;
            new_plugin.ButtonHeight = plugin_class.ButtonHeight;
            new_plugin.AlwaysRunPlugin = false; % Ensures plugin name is not in italics
            
            if isprop(plugin_class, 'Visibility')
                new_plugin.Visibility = plugin_class.Visibility;
            end
        end
        
    end    
end