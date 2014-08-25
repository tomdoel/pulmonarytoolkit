classdef PTKOrganisedPluginsModeList < handle
    % PTKOrganisedPluginsModeList. Part of the internal framework of the Pulmonary Toolkit.
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
    end
    
    methods
        function obj = PTKOrganisedPluginsModeList()
            obj.Clear;
        end
        
        function Clear(obj)
            obj.Modes = containers.Map;
        end
        
        function plugin_list = GetPlugins(obj, mode)
            if obj.Modes.isKey(mode)
                plugin_list = obj.Modes(mode);
            else
                plugin_list = containers.Map;
            end
        end        

        function AddList(obj, plugin_list, settings, gui_app, reporting)
            for plugin_filename = plugin_list
                plugin_name = plugin_filename{1}.First;
                plugin_wrapper = PTKPluginWrapperBase.AddPluginFromName(plugin_name, plugin_filename, settings, gui_app, reporting);
                if ~isempty(plugin_wrapper)
                    obj.Add(plugin_name, plugin_wrapper.ParsedPluginInfo.Mode, plugin_wrapper.ParsedPluginInfo.Category, plugin_wrapper);
                end
            end
        end

        
        function Add(obj, name, mode, category, plugin_wrapper)
            if obj.Modes.isKey(mode)
                mode_map = obj.Modes(mode);
            else
                mode_map = containers.Map;
            end
            
            if mode_map.isKey(category)
                category_map = mode_map(category);
            else
                category_map = containers.Map;
            end
            
            category_map(name) = plugin_wrapper;
            
            mode_map(category) = category_map;
            
            obj.Modes(mode) = mode_map;
        end
        
        
    end
end