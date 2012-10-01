classdef TDDatasetDiskCache < handle
    % TDDatasetDiskCache. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     A class used by TDPluginDependencyTracker to save and load plugin
    %     results and data associated with a particular dataset. This class
    %     ensures dependencies are correctly added, saved and validated when
    %     results are accessed or changed.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        PluginResultsInfo
        DiskCache
    end
    
    methods
        function obj = TDDatasetDiskCache(disk_cache, reporting)
            obj.DiskCache = disk_cache;
            obj.LoadCachedPluginResultsFile(reporting);
        end

        % Fetches a cached result for a plugin, but checks the dependencies to
        % ensure it is still valid, and if not returns an empty result.
        function [value, cache_info] = LoadPluginResult(obj, plugin_name, reporting)
            [value, cache_info] = obj.DiskCache.Load(plugin_name, reporting);
            if ~isempty(cache_info)
                dependencies = cache_info.DependencyList;
                if ~obj.PluginResultsInfo.CheckDependenciesValid(dependencies, reporting)
                    reporting.ShowWarning('TDDatasetDiskCache:InvalidDependency', ['The cached value for plugin ' plugin_name ' is no longer valid since some of its dependencies have changed. I am forcing this plugin to re-run to generate new results.'], []);
                    value = [];
                end
            end
        end
        
        % Stores a plugin result in the disk cache and updates cached dependency
        % information
        function SavePluginResult(obj, plugin_name, result, cache_info, reporting)
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name);
            obj.DiskCache.SaveWithInfo(plugin_name, result, cache_info, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        % Caches Dependency information
        function CachePluginInfo(obj, plugin_name, cache_info, reporting)
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        % Saves additional data associated with this dataset to the cache
        function SaveData(obj, data_filename, value, reporting)
            obj.DiskCache.Save(data_filename, value, reporting);
        end
        
        % Loads additional data associated with this dataset from the cache
        function value = LoadData(obj, data_filename, reporting)
            value = obj.DiskCache.Load(data_filename, reporting);
        end
        
        function cache_path = GetCachePath(obj, ~)
           cache_path = obj.DiskCache.CachePath;
        end
        
        function RemoveAllCachedFiles(obj, remove_framework_files, reporting)
            obj.DiskCache.RemoveAllCachedFiles(remove_framework_files, reporting);
        end
        
        function exists = Exists(obj, name, reporting)
            exists = obj.DiskCache.Exists(name, reporting);
        end
    end
    
    methods (Access = private)
        
        function LoadCachedPluginResultsFile(obj, reporting)
            cached_plugin_info = obj.DiskCache.Load(TDSoftwareInfo.CachedPluginInfoFileName, reporting);
            if isempty(cached_plugin_info)
                obj.PluginResultsInfo = TDPluginResultsInfo;
            else
                obj.PluginResultsInfo = cached_plugin_info;
            end
        end
        
        function SaveCachedPluginInfoFile(obj, reporting)
            obj.DiskCache.Save(TDSoftwareInfo.CachedPluginInfoFileName, obj.PluginResultsInfo, reporting);
        end
    end
end


