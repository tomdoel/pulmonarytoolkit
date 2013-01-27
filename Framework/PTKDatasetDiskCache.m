classdef PTKDatasetDiskCache < handle
    % PTKDatasetDiskCache. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     A class used by PTKPluginDependencyTracker to save and load plugin
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
        function obj = PTKDatasetDiskCache(disk_cache, reporting)
            obj.DiskCache = disk_cache;
            obj.LoadCachedPluginResultsFile(reporting);
        end

        % Fetches a cached result for a plugin, but checks the dependencies to
        % ensure it is still valid, and if not returns an empty result.
        function [value, cache_info] = LoadPluginResult(obj, plugin_name, reporting)
            [value, cache_info] = obj.DiskCache.Load(plugin_name, reporting);
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

        function valid = CheckDependencyValid(obj, next_dependency, reporting)
            valid = obj.PluginResultsInfo.CheckDependencyValid(next_dependency, reporting);
        end
    end
    
    methods (Access = private)
        
        function LoadCachedPluginResultsFile(obj, reporting)
            cached_plugin_info = obj.DiskCache.Load(PTKSoftwareInfo.CachedPluginInfoFileName, reporting);
            if isempty(cached_plugin_info)
                obj.PluginResultsInfo = PTKPluginResultsInfo;
            else
                obj.PluginResultsInfo = cached_plugin_info;
            end
        end
        
        function SaveCachedPluginInfoFile(obj, reporting)
            obj.DiskCache.Save(PTKSoftwareInfo.CachedPluginInfoFileName, obj.PluginResultsInfo, reporting);
        end
    end
end


