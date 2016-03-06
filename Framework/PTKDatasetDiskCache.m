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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        PluginResultsInfo
        
        ResultsDiskCache % Stores automatically generated plugin results for internal use
        EditedResultsDiskCache % Stores manual corrections to results
        ManualSegmentationsDiskCache % Stores manual segmentations
        MarkersDiskCache % Stores marker points
        FrameworkDatasetDiskCache % Stores framework cache files that are stored for each dataset
    end
    
    methods
        function obj = PTKDatasetDiskCache(dataset_uid, reporting)
            obj.ManualSegmentationsDiskCache = PTKDiskCache(PTKDirectories.GetManualSegmentationDirectoryAndCreateIfNecessary, dataset_uid, reporting);
            obj.ResultsDiskCache = PTKDiskCache(PTKDirectories.GetCacheDirectory, dataset_uid, reporting);
            obj.EditedResultsDiskCache = PTKDiskCache(PTKDirectories.GetEditedResultsDirectoryAndCreateIfNecessary, dataset_uid, reporting);
            obj.MarkersDiskCache = PTKDiskCache(PTKDirectories.GetMarkersDirectoryAndCreateIfNecessary, dataset_uid, reporting);
            obj.FrameworkDatasetDiskCache = PTKDiskCache(PTKDirectories.GetFrameworkDatasetCacheDirectoryAndCreateIfNecessary, dataset_uid, reporting);
            
            obj.LoadCachedPluginResultsFile(reporting);
        end

        function [value, cache_info] = LoadPluginResult(obj, plugin_name, context, reporting)
            % Fetches a cached result for a plugin
            
            [value, cache_info] = obj.ResultsDiskCache.Load(plugin_name, context, reporting);
        end
        
        function [value, cache_info] = LoadEditedPluginResult(obj, plugin_name, context, reporting)
            % Fetches edited cached result for a plugin
        
            [value, cache_info] = obj.EditedResultsDiskCache.Load(plugin_name, context, reporting);
        end
        
        function SavePluginResult(obj, plugin_name, result, cache_info, context, reporting)
            % Stores a plugin result in the disk cache and updates cached dependency
            % information
        
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context, false, reporting);
            obj.ResultsDiskCache.SaveWithInfo(plugin_name, result, cache_info, context, reporting);
            obj.PluginResultsInfo.AddCachedPluginInfo(plugin_name, cache_info, context, false, reporting);
            obj.SaveCachedPluginInfoFile(reporting);
        end
        
        function SaveEditedPluginResult(obj, plugin_name, context, edited_result, cache_info, reporting)
            % Stores a plugin result after semi-automatic editing in the edited
            % results disk cache and updates cached dependency information
        
            obj.PluginResultsInfo.DeleteCachedPluginInfo(plugin_name, context, true, reporting);
            obj.EditedResultsDiskCache.SaveWithInfo(plugin_name, edited_result, cache_info, context, reporting);
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
            obj.ResultsDiskCache.Delete(reporting);
        end
        
        function RemoveAllCachedFiles(obj, remove_framework_files, reporting)
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
            exists = obj.ResultsDiskCache.Exists(name, context, reporting);
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
    end
    
    methods (Access = private)
        
        function LoadCachedPluginResultsFile(obj, reporting)
            cached_plugin_info = obj.LoadData(PTKSoftwareInfo.CachedPluginInfoFileName, reporting);
            if isempty(cached_plugin_info)
                obj.PluginResultsInfo = PTKPluginResultsInfo;
            else
                obj.PluginResultsInfo = cached_plugin_info;
            end
        end
        
        function SaveCachedPluginInfoFile(obj, reporting)
            obj.SaveData(PTKSoftwareInfo.CachedPluginInfoFileName, obj.PluginResultsInfo, reporting);
        end
    end
end


