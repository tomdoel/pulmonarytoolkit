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
        function obj = TDDatasetDiskCache(disk_cache)
            obj.DiskCache = disk_cache;
            obj.LoadCachedPluginResultsFile;
        end

        % Fetches a cached result for a plugin, but checks the dependencies to
        % ensure it is still valid, and if not returns an empty result.
        function [value, cache_info] = LoadPluginResult(obj, plugin_name, reporting)
            [value, cache_info] = obj.DiskCache.Load(plugin_name);
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
            obj.DiskCache.Save(plugin_name, result, cache_info);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, reporting);
            obj.SaveCachedPluginInfoFile;
        end
        
        % Caches Dependency information
        function CachePluginInfo(obj, plugin_name, cache_info, reporting)
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, reporting);
            obj.SaveCachedPluginInfoFile;
        end
        
        % Saves additional data associated with this dataset to the cache
        function SaveData(obj, data_filename, value)
            obj.DiskCache.Save(data_filename, value);
        end
        
        % Loads additional data associated with this dataset from the cache
        function value = LoadData(obj, data_filename)
            value = obj.DiskCache.Load(data_filename);
        end
        
    end
    
    methods (Access = private)
        
        function LoadCachedPluginResultsFile(obj)
            cached_plugin_info = obj.DiskCache.Load(TDSoftwareInfo.CachedPluginInfoFileName);
            if isempty(cached_plugin_info)
                obj.PluginResultsInfo = TDPluginResultsInfo;
            else
                obj.PluginResultsInfo = cached_plugin_info;
            end
        end
        
        function SaveCachedPluginInfoFile(obj)
            obj.DiskCache.Save(TDSoftwareInfo.CachedPluginInfoFileName, obj.PluginResultsInfo);
        end
        
    end
    
end


