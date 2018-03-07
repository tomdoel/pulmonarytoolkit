classdef MimPluginResultsInfo < handle
    % MimPluginResultsInfo. Part of the internal MIM framework
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %     Provides metadata about plugin results, concerning the list of 
    %     dependencies used in generating each result for this dataset.
    %     This data is stored alongside plugin results in the disk cache, and is
    %     used to determine if a particular result is still valid. A result is
    %     still valid if the uid of each dependency in the dependency list 
    %     matches the uid of the current result for the matching plugin.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = protected)
        ResultsInfo
    end
    
    methods
        function obj = MimPluginResultsInfo(info_map)
            % Creates a new cache of plugin infos. To support conversion
            % from legacy classes, an existing map can be passed in;
            % otherwise this argument should be blank and a new map is
            % created
            
            if nargin > 0
                obj.ResultsInfo = info_map;
            else
                obj.ResultsInfo = containers.Map;
            end
        end
        
        function AddCachedPluginInfo(obj, plugin_name, cache_info, context, cache_type, reporting)
            % Adds dependency record for a particular plugin result
            plugin_key = MimPluginResultsInfo.GetKey(plugin_name, context, cache_type);
            if obj.ResultsInfo.isKey(plugin_key)
                reporting.Error('MimPluginResultsInfo:CachedInfoAlreadyPresent', 'Cached plugin info already present');
            end
            obj.ResultsInfo(plugin_key) = cache_info;
        end
        
        function DeleteCachedPluginInfo(obj, plugin_name, context, cache_type, ~)
            % Removes the dependency record for a particular plugin result
            plugin_key = MimPluginResultsInfo.GetKey(plugin_name, context, cache_type);
            if obj.ResultsInfo.isKey(plugin_key)
                obj.ResultsInfo.remove(plugin_key);
            end
        end
        
        function updated = UpdateCachedPluginInfo(obj, plugin_name, cache_info, context, cache_type, reporting)
            % Updates the cache info if the existance of the result has changed
            plugin_key = MimPluginResultsInfo.GetKey(plugin_name, context, cache_type);
            result_exists = ~isempty(cache_info);
            cache_exists = obj.ResultsInfo.isKey(plugin_key);
            
            if (result_exists && ~cache_exists)
                obj.AddCachedPluginInfo(plugin_name, cache_info, context, cache_type, reporting);
                updated = true;
                return;
            end
            
            if (~result_exists && cache_exists)
                obj.DeleteCachedPluginInfo(plugin_name, context, cache_type, reporting);
                updated = true;
                return;
            end
            
            updated = false;            
        end
        
        function info_exists = CachedInfoExists(obj, plugin_name, context, cache_type)
            % Returns true if a dependency entry exists in the cache

            plugin_key = MimPluginResultsInfo.GetKey(plugin_name, context, cache_type);
            info_exists = obj.ResultsInfo.isKey(plugin_key);
        end
        
        function cached_info = GetCachedInfo(obj, plugin_name, context, cache_type)
            % Returns the cached dependency information

            plugin_key = MimPluginResultsInfo.GetKey(plugin_name, context, cache_type);
            cached_info = obj.ResultsInfo(plugin_key);
        end        
    end
    
    methods (Static, Access = private)
        function plugin_key = GetKey(plugin_name, context, cache_type)
            if isempty(context)
                plugin_key = plugin_name;
            else
                plugin_key = [plugin_name '.' char(context)];
            end
            
            % For non plugin results, append to the key to ensure keys from
            % different caches don't clash
            if ~(CoreCompareUtilities.CompareEnumName(cache_type, MimCacheType.Results))
                plugin_key = [plugin_key, '_' char(cache_type)];
            end
        end
    end
end

