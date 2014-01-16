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
        
        ResultsDiskCache % stores automatically generated plugin results for internal use
        EditedResultsDiskCache % Stores manual corrections to results
        OutputDiskCache % stores exported results which can be loaded by other applications
    end
    
    methods
        function obj = PTKDatasetDiskCache(dataset_uid, reporting)
            obj.ResultsDiskCache = PTKDiskCache(PTKDirectories.GetCacheDirectory, dataset_uid, reporting);
            obj.EditedResultsDiskCache = PTKDiskCache(PTKDirectories.GetEditedResultsDirectoryAndCreateIfNecessary, dataset_uid, reporting);
            obj.OutputDiskCache = PTKDiskCache(PTKDirectories.GetOutputDirectoryAndCreateIfNecessary, dataset_uid, reporting);
            
            obj.LoadCachedPluginResultsFile(reporting);
        end

        % Fetches a cached result for a plugin
        function [value, cache_info] = LoadPluginResult(obj, plugin_name, context, reporting)
            if obj.EditedResultsDiskCache.Exists(plugin_name, context, reporting);
                [value, cache_info] = obj.EditedResultsDiskCache.Load(plugin_name, context, reporting);
                reporting.ShowMessage('PTKDatasetDiskCache:UsingEditedValue', ['Loading edited result for plugin ' plugin_name]);
            else
                [value, cache_info] = obj.ResultsDiskCache.Load(plugin_name, context, reporting);
            end
        end
        
        % Stores a plugin result in the disk cache and updates cached dependency
        % information
        function SavePluginResult(obj, plugin_name, result, cache_info, context, reporting)
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context);
            obj.ResultsDiskCache.SaveWithInfo(plugin_name, result, cache_info, context, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, context, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        % Stores a plugin result after semi-automatic editing in the edited
        % results disk cache and updates cached dependency information
        function SaveEditedPluginResult(obj, plugin_name, context, edited_result, cache_info, reporting)
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context);
            obj.EditedResultsDiskCache.SaveWithInfo(plugin_name, edited_result, cache_info, context, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, context, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        % Caches Dependency information
        function CachePluginInfo(obj, plugin_name, cache_info, context, reporting)
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, context, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        % Saves additional data associated with this dataset to the cache
        function SaveData(obj, data_filename, value, reporting)
            obj.ResultsDiskCache.Save(data_filename, value, [], reporting);
        end
        
        % Loads additional data associated with this dataset from the cache
        function value = LoadData(obj, data_filename, reporting)
            value = obj.ResultsDiskCache.Load(data_filename, [], reporting);
        end
        
        function cache_path = GetCachePath(obj, ~)
           cache_path = obj.ResultsDiskCache.CachePath;
        end
        
        function cache_path = GetEditedResultsPath(obj, ~)
           cache_path = obj.EditedResultsDiskCache.CachePath;
        end
        
        function cache_path = GetOutputPath(obj, ~)
            cache_path = obj.OutputDiskCache.CachePath;
        end
        
        function Delete(obj, reporting)
            obj.ResultsDiskCache.Delete(reporting);
        end
        
        function RemoveAllCachedFiles(obj, remove_framework_files, reporting)
            obj.ResultsDiskCache.RemoveAllCachedFiles(remove_framework_files, reporting);
        end
        
        function exists = Exists(obj, name, context, reporting)
            exists = obj.ResultsDiskCache.Exists(name, context, reporting);
            exists = exists || obj.EditedResultsDiskCache.Exists(name, context, reporting);
        end

        function valid = CheckDependencyValid(obj, next_dependency, reporting)
            valid = obj.PluginResultsInfo.CheckDependencyValid(next_dependency, reporting);
        end
    end
    
    methods (Access = private)
        
        function LoadCachedPluginResultsFile(obj, reporting)
            cached_plugin_info = obj.ResultsDiskCache.Load(PTKSoftwareInfo.CachedPluginInfoFileName, [], reporting);
            if isempty(cached_plugin_info)
                obj.PluginResultsInfo = PTKPluginResultsInfo;
            else
                obj.PluginResultsInfo = cached_plugin_info;
            end
        end
        
        function SaveCachedPluginInfoFile(obj, reporting)
            obj.ResultsDiskCache.Save(PTKSoftwareInfo.CachedPluginInfoFileName, obj.PluginResultsInfo, [], reporting);
        end
    end
end


