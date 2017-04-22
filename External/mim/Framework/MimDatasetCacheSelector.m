classdef MimDatasetCacheSelector < handle
    % MimDatasetCacheSelector. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %     A class used by MimPluginDependencyTracker to save and load plugin
    %     results and data associated with a particular dataset. This class
    %     ensures dependencies are correctly added, saved and validated when
    %     results are accessed or changed.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        Config
        PluginResultsInfo
        
        ResultsDiskAndMemoryCache % Stores automatically generated plugin results for internal use
        EditedResultsDiskCache % Stores manual corrections to results
        ManualSegmentationsDiskCache % Stores manual segmentations
        MarkersDiskCache % Stores marker points
        FrameworkDatasetDiskCache % Stores framework cache files that are stored for each dataset
        FrameworkAppDef
    end
    
    events
        % This event is fired when a marker set is added or removed
        MarkersChanged
        
        % This event is fired when the manual segmentation list for this dataset has changed
        ManualSegmentationsChanged
    end
    
    methods
        function obj = MimDatasetCacheSelector(dataset_uid, framework_app_def, reporting)
            obj.Config = framework_app_def.GetFrameworkConfig;
            obj.FrameworkAppDef = framework_app_def;
            directories = framework_app_def.GetFrameworkDirectories;
            obj.ManualSegmentationsDiskCache = MimDiskCache(directories.GetManualSegmentationDirectoryAndCreateIfNecessary, dataset_uid, obj.Config, true, reporting);
            obj.ResultsDiskAndMemoryCache = MimDatasetDiskAndMemoryCache(dataset_uid, framework_app_def, reporting);
            obj.EditedResultsDiskCache = MimDiskCache(directories.GetEditedResultsDirectoryAndCreateIfNecessary, dataset_uid, obj.Config, true, reporting);
            obj.MarkersDiskCache = MimDiskCache(directories.GetMarkersDirectoryAndCreateIfNecessary, dataset_uid, obj.Config, true, reporting);
            obj.FrameworkDatasetDiskCache = MimDiskCache(directories.GetFrameworkDatasetCacheDirectory, dataset_uid, obj.Config, false, reporting);
            
            obj.LoadCachedPluginResultsFile(reporting);
        end

        function [value, cache_info] = LoadPluginResult(obj, plugin_name, context, memory_cache_policy, reporting)
            % Fetches a cached result for a plugin
            
            [value, cache_info] = obj.ResultsDiskAndMemoryCache.Load(plugin_name, context, memory_cache_policy, reporting);
        end
        
        function SavePluginResult(obj, plugin_name, result, cache_info, context, disk_cache_policy, memory_cache_policy, reporting)
            % Stores a plugin result in the disk cache and updates cached dependency
            % information

            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context, false, reporting);
            if ~isempty(result)
                obj.ResultsDiskAndMemoryCache.SaveWithInfo(plugin_name, result, cache_info, context, disk_cache_policy, memory_cache_policy, reporting);
            end
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, context, false, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        function cache_path = GetCachePath(obj, ~)
            % Returns the path to the plugin results cache
            
           cache_path = obj.ResultsDiskAndMemoryCache.GetCachePath();
        end
        
        function [value, cache_info] = LoadEditedPluginResult(obj, plugin_name, context, reporting)
            % Fetches edited cached result for a plugin
        
            [value, cache_info] = obj.EditedResultsDiskCache.Load(plugin_name, context, reporting);
        end
        
        function SaveEditedResult(obj, plugin_name, context, edited_result, cache_info, reporting)
            % Stores a plugin result after semi-automatic editing in the edited
            % results disk cache and updates cached dependency information
        
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context, true, reporting);
            obj.EditedResultsDiskCache.SaveWithInfo(plugin_name, edited_result, cache_info, context, MimCachePolicy.Permanent, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, context, true, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        function exists = EditedResultExists(obj, name, context, reporting)
            exists = obj.EditedResultsDiskCache.Exists(name, context, reporting);
        end
        
        function DeleteEditedPluginResult(obj, plugin_name, reporting)
            % Deletes edited results associated with a particular plugin
            
            dir_list = obj.EditedResultsDiskCache.DeleteFileForAllContexts(plugin_name, reporting);
            for context = dir_list
                obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context{1}, true, reporting);
            end
        end
        
        function cache_path = GetEditedResultsPath(obj, ~)
           cache_path = obj.EditedResultsDiskCache.CachePath;
        end
 
        function UpdateEditedResults(obj, plugin_name, cache_info, context, reporting)
            % Updates the results cache if the existance of an edited
            % result has changed
            
            obj.PluginResultsInfo.UpdateEditedResults(plugin_name, cache_info, context, reporting);
        end
        
        function value = LoadData(obj, data_filename, reporting)
            % Loads additional data associated with this dataset from the cache

            % PTK versions 0.6 and earlier stored the data cache files in
            % the same folder as the plugin results cache files. If we find
            % them here, load them and also move them to the framework
            % cache folder for this dataset.
            if ~obj.FrameworkDatasetDiskCache.Exists(data_filename, [], reporting) && obj.ResultsDiskAndMemoryCache.Exists(data_filename, [], reporting)
                reporting.Log(['Moving framework cache file to framework cache: ' data_filename]);
                value = obj.ResultsDiskAndMemoryCache.Load(data_filename, [], MimCachePolicy.Off, reporting);
                obj.FrameworkDatasetDiskCache.Save(data_filename, value, [], MimStorageFormat.Mat, reporting);
                obj.ResultsDiskAndMemoryCache.DeleteCacheFile(data_filename, [], reporting);
            else        
                value = obj.FrameworkDatasetDiskCache.Load(data_filename, [], reporting);
            end
        end
        
        function SaveData(obj, data_filename, value, reporting)
            % Saves additional data associated with this dataset to the cache
            
            obj.FrameworkDatasetDiskCache.Save(data_filename, value, [], MimStorageFormat.Mat, reporting);
        end
        
        function value = LoadManualSegmentation(obj, filename, reporting)
            % Loads a manual segmentation data associated with this dataset from the cache
            
            value = obj.ManualSegmentationsDiskCache.Load(filename, [], reporting);
        end
        
        function SaveManualSegmentation(obj, name, value, reporting)
            % Saves a manual segmentation associated with this dataset to the cache
            
            obj.ManualSegmentationsDiskCache.Save(name, value, [], MimStorageFormat.Mat, reporting);
            obj.NotifyManualSegmentationsChanged(name);
        end
        
        function exists = ManualSegmentationExists(obj, name, reporting)
            % Returns true if the specified manual segmentation result exists
            
            exists = obj.ManualSegmentationsDiskCache.Exists(name, [], reporting);
        end
        
        function file_list = GetListOfManualSegmentations(obj)
            % Returns a list of manual segmentation results in the cache
            
            file_list = obj.ManualSegmentationsDiskCache.GetAllFilesInCache;
        end

        function DeleteManualSegmentation(obj, segmentation_name, reporting)
            % Deletes manual segmentation results
            
            obj.ManualSegmentationsDiskCache.DeleteFileForAllContexts(segmentation_name, reporting);
            obj.NotifyManualSegmentationsChanged(segmentation_name);
        end
        
        function value = LoadMarkerPoints(obj, filename, reporting)
            % Loads marker points associated with this dataset from the cache
            
            value = obj.MarkersDiskCache.Load(filename, [], reporting);
        end
        
        function SaveMarkerPoints(obj, data_filename, value, reporting)
            % Saves marker points associated with this dataset to the cache
            
            obj.MarkersDiskCache.Save(data_filename, value, [], MimStorageFormat.Mat, reporting);
            obj.NotifyMarkersChanged(data_filename);
        end
        
        function exists = MarkerSetExists(obj, name, reporting)
            % Returns true if the specified marker set exists
            
            exists = obj.MarkersDiskCache.Exists(name, [], reporting);
        end
        
        function file_list = GetListOfMarkerSets(obj)
            % Returns the names of all stored marker sets
            
            file_list = obj.MarkersDiskCache.GetAllFilesInCache;
        end
        
        function DeleteMarkerSet(obj, name, reporting)
            % Deletes marker set
            
            obj.MarkersDiskCache.DeleteFileForAllContexts(name, reporting);
            obj.NotifyMarkersChanged(name);
        end
        
        function Delete(obj, reporting)
            obj.ResultsDiskAndMemoryCache.Delete(reporting);
            obj.FrameworkDatasetDiskCache.Delete(reporting);
        
        function CachePluginInfo(obj, plugin_name, cache_info, context, is_edited, reporting)
            % Caches Dependency information
            
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context, is_edited, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, context, is_edited, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        function RemoveAllCachedFiles(obj, remove_framework_files, reporting)
            obj.ResultsDiskAndMemoryCache.RemoveAllCachedFiles(remove_framework_files, reporting);
        end
        
        function exists = Exists(obj, name, context, reporting)
            exists = obj.ResultsDiskAndMemoryCache.Exists(name, context, reporting);
            exists = exists || obj.EditedResultsDiskCache.Exists(name, context, reporting);
        end

        function [valid, edited_result_exists] = CheckDependencyValid(obj, next_dependency, reporting)
            [valid, edited_result_exists] = obj.PluginResultsInfo.CheckDependencyValid(next_dependency, reporting);
        end
        
        function ClearTemporaryMemoryCache(obj)
            obj.ResultsDiskAndMemoryCache.ClearTemporaryMemoryCache();
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
        
        function NotifyMarkersChanged(obj, name)
            obj.notify('MarkersChanged', CoreEventData(name));
        end
        
        function NotifyManualSegmentationsChanged(obj, name)
            obj.notify('ManualSegmentationsChanged', CoreEventData(name));
        end
    end
end


