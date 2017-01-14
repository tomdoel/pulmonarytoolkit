classdef MimDatasetCacheSelector < handle
    % MimDatasetCacheSelector. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     A class used by MimPluginDependencyTracker to save and load plugin
    %     results and data associated with a particular dataset. This class
    %     ensures dependencies are correctly added, saved and validated when
    %     results are accessed or changed.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        Config
        PluginResultsInfo
        
        ResultsDiskCache % Stores automatically generated plugin results for internal use
        ResultsMemoryCache % Stores automatically generated plugin results for internal use
        EditedResultsDiskCache % Stores manual corrections to results
        ManualSegmentationsDiskCache % Stores manual segmentations
        MarkersDiskCache % Stores marker points
        FrameworkDatasetDiskCache % Stores framework cache files that are stored for each dataset
        FrameworkAppDef
    end
    
    methods
        function obj = MimDatasetCacheSelector(dataset_uid, framework_app_def, reporting)
            obj.Config = framework_app_def.GetFrameworkConfig;
            obj.FrameworkAppDef = framework_app_def;
            directories = framework_app_def.GetFrameworkDirectories;
            obj.ManualSegmentationsDiskCache = MimDiskCache(directories.GetManualSegmentationDirectoryAndCreateIfNecessary, dataset_uid, obj.Config, reporting);
            obj.ResultsDiskCache = MimDiskCache(directories.GetCacheDirectory, dataset_uid, obj.Config, reporting);
            obj.ResultsMemoryCache = MimMemoryCache(reporting);
            obj.EditedResultsDiskCache = MimDiskCache(directories.GetEditedResultsDirectoryAndCreateIfNecessary, dataset_uid, obj.Config, reporting);
            obj.MarkersDiskCache = MimDiskCache(directories.GetMarkersDirectoryAndCreateIfNecessary, dataset_uid, obj.Config, reporting);
            obj.FrameworkDatasetDiskCache = MimDiskCache(directories.GetFrameworkDatasetCacheDirectory, dataset_uid, obj.Config, reporting);
            
            obj.LoadCachedPluginResultsFile(reporting);
        end

        function [value, cache_info] = LoadPluginResult(obj, plugin_name, context, memory_cache_policy, reporting)
            % Fetches a cached result for a plugin
            
            if obj.ResultsMemoryCache.Exists(plugin_name, context, reporting)
                [value, cache_info] = obj.ResultsMemoryCache.Load(plugin_name, context, reporting);
            else
                [value, cache_info] = obj.ResultsDiskCache.Load(plugin_name, context, reporting);
                obj.ResultsMemoryCache.SaveWithInfo(plugin_name, value, cache_info, context, memory_cache_policy, reporting);
            end
        end
        
        function [value, cache_info] = LoadEditedPluginResult(obj, plugin_name, context, reporting)
            % Fetches edited cached result for a plugin
        
            [value, cache_info] = obj.EditedResultsDiskCache.Load(plugin_name, context, reporting);
        end
        
        function SavePluginResult(obj, plugin_name, result, cache_info, context, disk_cache_policy, memory_cache_policy, reporting)
            % Stores a plugin result in the disk cache and updates cached dependency
            % information

            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context, false, reporting);
            if ~isempty(result)
                obj.ResultsDiskCache.SaveWithInfo(plugin_name, result, cache_info, context, disk_cache_policy, reporting);
                obj.ResultsMemoryCache.SaveWithInfo(plugin_name, result, cache_info, context, memory_cache_policy, reporting);
            end
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, context, false, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        function SaveEditedResult(obj, plugin_name, context, edited_result, cache_info, reporting)
            % Stores a plugin result after semi-automatic editing in the edited
            % results disk cache and updates cached dependency information
        
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context, true, reporting);
            obj.EditedResultsDiskCache.SaveWithInfo(plugin_name, edited_result, cache_info, context, MimCachePolicy.Permanent, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, context, true, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        function CachePluginInfo(obj, plugin_name, cache_info, context, is_edited, reporting)
            % Caches Dependency information
            
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context, is_edited, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, context, is_edited, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        function UpdateEditedResults(obj, plugin_name, cache_info, context, reporting)
            % Updates the results cache if the existance of an edited
            % result has changed
            
            obj.PluginResultsInfo.UpdateEditedResults(plugin_name, cache_info, context, reporting);
        end
        
        function SaveData(obj, data_filename, value, reporting)
            % Saves additional data associated with this dataset to the cache
            
            obj.FrameworkDatasetDiskCache.Save(data_filename, value, [], reporting);
        end
        
        function value = LoadData(obj, data_filename, reporting)
            % Loads additional data associated with this dataset from the cache

            % PTK versions 0.6 and earlier stored the data cache files in
            % the same folder as the plugin results cache files. If we find
            % them here, load them and also move them to the framework
            % cache folder for this dataset.
            if ~obj.FrameworkDatasetDiskCache.Exists(data_filename, [], reporting) && obj.ResultsDiskCache.Exists(data_filename, [], reporting)
                reporting.Log(['Moving framework cache file to framework cache: ' data_filename]);
                value = obj.ResultsDiskCache.Load(data_filename, [], reporting);
                obj.FrameworkDatasetDiskCache.Save(data_filename, value, [], reporting);
                obj.ResultsDiskCache.DeleteCacheFile(data_filename, [], reporting);
            else        
                value = obj.FrameworkDatasetDiskCache.Load(data_filename, [], reporting);
            end
        end
        
        function SaveManualSegmentation(obj, filename, value, context, reporting)
            % Saves a manual segmentation associated with this dataset to the cache
            
            obj.ManualSegmentationsDiskCache.Save(filename, value, context, reporting);
        end
        
        function value = LoadManualSegmentation(obj, filename, context, reporting)
            % Loads a manual segmentation data associated with this dataset from the cache
            
            value = obj.ManualSegmentationsDiskCache.Load(filename, context, reporting);
        end
        
        function SaveMarkerPoints(obj, data_filename, value, reporting)
            % Saves marker points associated with this dataset to the cache
            
            obj.MarkersDiskCache.Save(data_filename, value, [], reporting);
        end
        
        function value = LoadMarkerPoints(obj, filename, reporting)
            % Loads marker points associated with this dataset from the cache
            
            value = obj.MarkersDiskCache.Load(filename, [], reporting);
        end
        
        function cache_path = GetCachePath(obj, ~)
           cache_path = obj.ResultsDiskCache.CachePath;
        end
        
        function cache_path = GetEditedResultsPath(obj, ~)
           cache_path = obj.EditedResultsDiskCache.CachePath;
        end
 
        function Delete(obj, reporting)
            obj.ResultsMemoryCache.Delete(reporting);
            obj.FrameworkDatasetDiskCache.Delete(reporting);
            obj.ResultsDiskCache.Delete(reporting);
        end
        
        function RemoveAllCachedFiles(obj, remove_framework_files, reporting)
            obj.ResultsMemoryCache.RemoveAllCachedFiles(remove_framework_files, reporting);
            obj.ResultsDiskCache.RemoveAllCachedFiles(remove_framework_files, reporting);
        end
        
        function DeleteEditedPluginResult(obj, plugin_name, reporting)
            % Deletes edited results associated with a particular plugin
            
            dir_list = obj.EditedResultsDiskCache.DeleteFileForAllContexts(plugin_name, reporting);
            for context = dir_list
                obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context{1}, true, reporting);
            end
        end
        
        function DeleteManualSegmentation(obj, segmentation_name, reporting)
            % Deletes manual segmentation results
            
            obj.ManualSegmentationsDiskCache.DeleteFileForAllContexts(segmentation_name, reporting);
        end
        
        function exists = Exists(obj, name, context, reporting)
            exists = obj.ResultsMemoryCache.Exists(name, context, reporting);
            exists = exists || obj.ResultsDiskCache.Exists(name, context, reporting);
            exists = exists || obj.EditedResultsDiskCache.Exists(name, context, reporting);
        end

        function exists = EditedResultExists(obj, name, context, reporting)
            exists = obj.EditedResultsDiskCache.Exists(name, context, reporting);
        end
        
        function [valid, edited_result_exists] = CheckDependencyValid(obj, next_dependency, reporting)
            [valid, edited_result_exists] = obj.PluginResultsInfo.CheckDependencyValid(next_dependency, reporting);
        end
        
        function file_list = GetListOfManualSegmentations(obj)
            file_list = obj.ManualSegmentationsDiskCache.GetAllFilesInCache;
        end

        function file_list = GetListOfMarkerSets(obj)
            file_list = obj.MarkersDiskCache.GetAllFilesInCache;
        end
        
        function ClearTemporaryMemoryCache(obj)
            obj.ResultsMemoryCache.ClearTemporaryResults;
        end
    end
    
    methods (Access = private)
        function LoadCachedPluginResultsFile(obj, reporting)
            cached_plugin_info = obj.LoadData(obj.Config.CachedPluginInfoFileName, reporting);
            if isempty(cached_plugin_info)
                obj.PluginResultsInfo = obj.FrameworkAppDef.GetClassFactory.CreatePluginResultsInfo;
            else                
                if ~isa(cached_plugin_info, 'MimPluginResultsInfo')
                    reporting.Error('MimDatasetCacheSelector:UnrecognisedFormat', 'The cached plugin info is not of the recognised class type');
                end
                
                obj.PluginResultsInfo = cached_plugin_info;
            end
        end
        
        function SaveCachedPluginInfoFile(obj, reporting)
            obj.SaveData(obj.Config.CachedPluginInfoFileName, obj.PluginResultsInfo, reporting);
        end
    end
end


