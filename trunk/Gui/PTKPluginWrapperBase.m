classdef PTKPluginWrapperBase < handle
    % PTKPluginWrapperBase. Part of the internal framework of the Pulmonary Toolkit.
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
    
    properties
        ParsedPluginInfo
    end
    
    properties (SetAccess = protected)
        GuiApp
        Location
        PluginName
        PluginObject
    end
    
    methods (Access = protected)
        function obj = PTKPluginWrapperBase(name, plugin_object, parsed_plugin_info, gui_app)
            obj.GuiApp = gui_app;
            obj.PluginName = name;
            obj.PluginObject = plugin_object;
            obj.ParsedPluginInfo = parsed_plugin_info;
            obj.Location = parsed_plugin_info.Location;
        end
    end
    
    methods (Static)
        function plugin = AddPluginFromName(plugin_name, plugin_filename, gui_app, reporting)
            plugin = [];
            try
                if (exist(plugin_name, 'class') == 8)
                    plugin_handle = str2func(plugin_name);
                    plugin_class_object = feval(plugin_handle);
                    if isa(plugin_class_object, 'PTKPlugin')
                        is_plugin = true;
                        is_gui_plugin = false;
                    elseif isa(plugin_class_object, 'PTKGuiPlugin')
                        is_plugin = true;
                        is_gui_plugin = true;
                    else
                        is_plugin = false;
                        is_gui_plugin = false;
                    end
                    if is_plugin
                        hide_plugin = plugin_class_object.HidePluginInDisplay || (~gui_app.DeveloperMode && isprop(plugin_class_object, 'Visibility') && strcmp(plugin_class_object.Visibility, 'Developer'));
                        if ~hide_plugin
                            % Parse the plugin class properties into a data structure
                            if is_gui_plugin
                                parsed_plugin_info = PTKParseGuiPluginClass(plugin_name, plugin_class_object, plugin_filename{1}.Second, reporting);
                                plugin = PTKGuiPluginWrapper(plugin_name, plugin_class_object, parsed_plugin_info, gui_app);
                            else
                                parsed_plugin_info = PTKParsePluginClass(plugin_name, plugin_class_object, plugin_filename{1}.Second, reporting);
                                plugin = PTKPluginWrapper(plugin_name, plugin_class_object, parsed_plugin_info, gui_app);
                            end
                        end
                    else
                        reporting.ShowWarning('PTKPluginWrapper:FileNotPlugin', ['The file ' plugin_name ' was found in a plugins directory but does not appear to be a plugin class. I am ignoring this file. If this is not a plugin class, you should remove thie file from the plugin directory; otherwise check the file for errors.'], []);
                    end
                else
                    reporting.ShowWarning('PTKPluginWrapper:FileNotPlugin', ['The file ' plugin_name ' was found in a plugins directory but does not appear to be a plugin class. I am ignoring this file. If this is not a plugin class, you should remove thie file from the plugin directory; otherwise check the file for errors.'], []);
                end
            catch ex
                reporting.ShowWarning('PTKPluginWrapper:ParsePluginError', ['The file ' plugin_name ' was found in a plugins directory but does not appear to be a plugin class, or contains errors. I am ignoring this file. If this is not a plugin class, you should remove thie file from the plugin directory; otherwise check the file for errors.'], ex.message);
            end
        end
        
    end
end