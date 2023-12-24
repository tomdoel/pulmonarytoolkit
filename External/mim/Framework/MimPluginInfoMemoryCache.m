classdef MimPluginInfoMemoryCache < handle
    % Stores a map of plugin names to plugin handles and plugin info structures
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        PluginHandleMap
        PluginInfoMap
    end
    
    methods
        function obj = MimPluginInfoMemoryCache()
            obj.PluginHandleMap = containers.Map();
            obj.PluginInfoMap = containers.Map();
        end
        
        function plugin_info = GetPluginInfo(obj, plugin_name, category, reporting)
            [is_mim_plugin, plugin_class] = obj.PopulateCache(plugin_name, category, reporting);
            if isempty(plugin_class)
                reporting.Error('MimPluginInfoMemoryCache:PluginNotFound', ['The plugin ' plugin_name ' was not found. Please ensure this is a MimPlugin class and it is in the path.']);
            end
            if ~is_mim_plugin
                reporting.Error('MimPluginInfoMemoryCache:NotAPlugin', ['A file ' plugin_name ' was found but is not a valid MimPlugin class. Please ensure this is a MimPlugin class.']);
            end
            plugin_info = obj.PluginInfoMap(plugin_name);
        end
        
        function plugin_handle = GetPluginHandle(obj, plugin_name, category, reporting)
            [is_mim_plugin, plugin_class] = obj.PopulateCache(plugin_name, category, reporting);
            if isempty(plugin_class)
                reporting.Error('MimPluginInfoMemoryCache:PluginNotFound', ['The plugin ' plugin_name ' was not found. Please ensure this is a MimPlugin class and it is in the path.']);
            end
            if ~is_mim_plugin
                reporting.Error('MimPluginInfoMemoryCache:NotAPlugin', ['A file ' plugin_name ' was found but is not a valid MimPlugin class. Please ensure this is a MimPlugin class.']);
            end
            plugin_handle = obj.PluginHandleMap(plugin_name);
        end
        
        function [is_mim_plugin, plugin_class_object] = IsPlugin(obj, plugin_name, category, reporting)
            [is_mim_plugin, plugin_class_object] = obj.PopulateCache(plugin_name, category, reporting);
        end
        
        function Clear(obj)
            obj.PluginHandleMap = containers.Map();
            obj.PluginInfoMap = containers.Map();
        end
    end
    
    methods (Access = private)
        function [is_mim_plugin, plugin_class] = PopulateCache(obj, plugin_name, category, reporting)
            if obj.PluginHandleMap.isKey(plugin_name) && obj.PluginInfoMap.isKey(plugin_name)
                is_mim_plugin = true;
                plugin_class = obj.PluginHandleMap(plugin_name);
                return;
            end
            
            if (exist(plugin_name, 'class') ~= 8)
                is_mim_plugin = false;
                plugin_class = [];
                return;
            end

            plugin_handle = str2func(plugin_name);
            plugin_class = feval(plugin_handle);

            if ~isa(plugin_class, 'MimPlugin')
                is_mim_plugin = false;
                return;
            end

            is_mim_plugin = true;
            obj.PluginHandleMap(plugin_name) = plugin_class;

            % Parse the class properties into a data structure
            plugin_info = MimParsePluginClass(plugin_name, plugin_class, category, reporting);

            obj.PluginInfoMap(plugin_name) = plugin_info;
        end
    end
end

