classdef MimDatasetDiskAndMemoryCache < handle
    % A class used by MimDatasetCacheSelector to save and load plugin
    % results to either a memory cache or a disk cache.
    %    
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        ResultsDiskCache   % Stores results on disk
        ResultsMemoryCache % Stores results in memory
    end
    
    methods
        function obj = MimDatasetDiskAndMemoryCache(dataset_uid, framework_app_def, reporting)
            config = framework_app_def.GetFrameworkConfig();
            directories = framework_app_def.GetFrameworkDirectories();
            obj.ResultsDiskCache = MimDiskCache(directories.GetCacheDirectory(), dataset_uid, config, false, reporting);
            obj.ResultsMemoryCache = MimMemoryCache(reporting);
        end

        function exists = Exists(obj, name, context, reporting)
            % Returns true if result exists in either memory or disk cache
            
            exists = obj.ResultsMemoryCache.Exists(name, context, reporting);
            exists = exists || obj.ResultsDiskCache.Exists(name, context, reporting);
        end
        
        function DeleteCacheFile(obj, name, context, reporting)
            % Removes a result from the memory and disk caches
            
            obj.ResultsMemoryCache.DeleteCacheFile(name, context, reporting);
            obj.ResultsDiskCache.DeleteCacheFile(name, context, reporting);
        end

        function SaveWithInfo(obj, name, value, info, context, disk_cache_policy, memory_cache_policy, reporting)
            % Save a result to the memory and disk caches
            
            obj.ResultsDiskCache.SaveWithInfo(name, value, info, context, disk_cache_policy, reporting);
            obj.ResultsMemoryCache.SaveWithInfo(name, value, info, context, memory_cache_policy, reporting);
        end

        function [value, cache_info] = Load(obj, plugin_name, context, memory_cache_policy, reporting)
            % Fetches a cached result from the memory or disk cache
            
            if obj.ResultsMemoryCache.Exists(plugin_name, context, reporting)
                [value, cache_info] = obj.ResultsMemoryCache.Load(plugin_name, context, reporting);
            else
                [value, cache_info] = obj.ResultsDiskCache.Load(plugin_name, context, reporting);
                if ~isempty(value)
                    obj.ResultsMemoryCache.SaveWithInfo(plugin_name, value, cache_info, context, memory_cache_policy, reporting);
                end
            end
        end
        
        function Delete(obj, reporting)
            % Wipes the disk and memory caches
            
            obj.ResultsMemoryCache.Delete(reporting);
            obj.ResultsDiskCache.Delete(reporting);
        end
        
        function RemoveAllCachedFiles(obj, remove_framework_files, reporting)
            % Removes files from memory and disk caches
            
            obj.ResultsMemoryCache.RemoveAllCachedFiles(remove_framework_files, reporting);
            obj.ResultsDiskCache.RemoveAllCachedFiles(remove_framework_files, reporting);
        end

        function dir_list = DeleteFileForAllContexts(obj, name, reporting)
            % Delete particular results from all contexts in this dataset
            
            dir_list_1 = obj.ResultsMemoryCache.DeleteFileForAllContexts(name, reporting);
            dir_list_2 = obj.ResultsDiskCache.DeleteFileForAllContexts(name, reporting);
            dir_list = [dir_list_1, dir_list_2];
        end        
        
        function file_list = GetAllFilesInCache(obj)
            % Get a list of files in the disk cache
            
            file_list_1 = obj.ResultsDiskCache.GetAllFilesInCache();
            file_list_2 = obj.ResultsDiskCache.GetAllFilesInCache();
            file_list = unique([file_list_1, file_list_2]);
        end
        
        function cache_path = GetCachePath(obj, ~)
            % Returns the path to the disk cache
            
           cache_path = obj.ResultsDiskCache.CachePath;
        end        
        
        function ClearTemporaryMemoryCache(obj)
            % Clears results from the memory cache that are marked as
            % temporary
            
            obj.ResultsMemoryCache.ClearTemporaryResults();
        end
    end
end


