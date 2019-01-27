classdef (Sealed) MimFrameworkSingleton < handle
    % MimFrameworkSingleton. The singleton used by all instances of MimMain
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the TD MIM Toolkit.
    %
    %     Some parts of the MIM framework (such as the image database) rely on
    %     in-memory caches. Typically changes will be written to disk when the
    %     caches change, but they will not be reloaded at each operation for
    %     efficiency reasons. This would cause inconsistencies if multiple instances
    %     of these classes were running simultaneously.
    %
    %     To prevent this, cached information is held in a singleton class which all
    %     instances of MimMain get access to.
    %
    %     MimFrameworkSingleton is a singleton. It cannot be created using the
    %     constructor; instead call MimFrameworkSingleton.GetFrameworkSingleton;
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        FrameworkAppDef
        ImageDatabase      % Database of image files
        MexCache           % Information about mex files which is cached on disk
        LinkedDatasetRecorder
        DatasetApiCache % Stores MimDatasetCacheSelector objects in memory
        LinkedDatasetChooserMemoryCache
        PluginInfoMemoryCache % Stores parsed plugin classes in memory
    end
        
    methods (Static)
        function framework_singleton = GetFrameworkSingleton(framework_app_def, reporting)
            % Returns the FrameworkSingleton, creating if necessary
            persistent FrameworkSingleton
            if isempty(FrameworkSingleton) || ~isvalid(FrameworkSingleton)
                FrameworkSingleton = MimFrameworkSingleton(framework_app_def, reporting);
            end
            framework_singleton = FrameworkSingleton;
        end
    end
    
    methods
        function CompileMexFileIfRequired(obj, files_to_compile, output_directory, reporting)
            % Recompiles mex files if they have changed
            if ~isdeployed
                CoreCompileMexFiles(obj.MexCache, output_directory, files_to_compile, false, ' Run MimMain.Recompile() to force recompilation.', reporting);
            end
        end
        
        function Recompile(obj, files_to_compile, output_directory, reporting)
            % Forces recompilation of mex files
            
            if ~isdeployed
                CoreCompileMexFiles(obj.MexCache, output_directory, files_to_compile, true, ' Run MimMain.Recompile() to force recompilation.', reporting);
            end
        end
        
        function RebuildDatabase(obj, reporting)
            obj.ImageDatabase.Rebuild([], true, obj.FrameworkAppDef, reporting)
        end
    
        function AddToDatabase(obj, image_uid, reporting)
            
            % CreateDatasetFromInfo() can import new data, so we may need to add
            % to the image database
            if ~obj.ImageDatabase.SeriesExists(image_uid)
                obj.ImageDatabase.Rebuild({image_uid}, false, obj.FrameworkAppDef, reporting);
            end
        end
        
        function ReportChangesToDatabase(obj)
            obj.ImageDatabase.ReportChangesToDatabase;
        end
        
        function series_info = GetSeriesInfo(obj, series_uid)
            series_info = obj.ImageDatabase.GetSeries(series_uid);
        end
        
        function SaveImageDatabase(obj, reporting)
            obj.ImageDatabase.SaveDatabase(reporting);
        end
        
        function [uids, patient_ids] = ImportData(obj, filename, reporting)
            [uids, patient_ids] = MimImageImporter(filename, obj.ImageDatabase, reporting);
        end
        
        function image_database = GetImageDatabase(obj)
            image_database = obj.ImageDatabase;
        end
        
        function linked_recorder = GetLinkedDatasetRecorder(obj)
            linked_recorder = obj.LinkedDatasetRecorder;
        end
        
        function dataset_memory_cache = GetDatasetApiCache(obj)
            dataset_memory_cache = obj.DatasetApiCache;
        end
        
        function linked_recorder_memory_cache = GetLinkedDatasetChooserMemoryCache(obj)
            linked_recorder_memory_cache = obj.LinkedDatasetChooserMemoryCache;
        end
        
        function plugin_info_memory_cache = GetPluginInfoMemoryCache(obj)
            plugin_info_memory_cache = obj.PluginInfoMemoryCache;
        end

        function class_factory = GetClassFactory(obj)
            class_factory = obj.FrameworkAppDef.GetClassFactory;
        end
    end
    
    methods (Access = private)
        function obj = MimFrameworkSingleton(framework_app_def, reporting)
            obj.FrameworkAppDef = framework_app_def;
            
            % If we can't find an XML cache file, we search for a legacy
            % cache file and load that if found
            mex_cache_filename = framework_app_def.GetFrameworkDirectories.GetMexCacheFilePath;
            legacy_mex_cache_filename = framework_app_def.GetFrameworkDirectories.GetLegacyMexCacheFilePath;
            if (2 ~= exist(mex_cache_filename, 'file')) && (2 == exist(legacy_mex_cache_filename, 'file'))
                obj.MexCache = PTKFrameworkCache.LoadLegacyCache(legacy_mex_cache_filename, mex_cache_filename, reporting);
                if ~isempty(obj.MexCache)
                    obj.MexCache.SaveCache(reporting);
                    delete(legacy_mex_cache_filename);
                end
            end
            
            if isempty(obj.MexCache)
                obj.MexCache = CoreMexCache.LoadCache(mex_cache_filename, reporting);
            end
            
            obj.LinkedDatasetRecorder = PTKLinkedDatasetRecorder.Load(framework_app_def, reporting);
            obj.DatasetApiCache = MimDatasetApiCache(framework_app_def);
            obj.PluginInfoMemoryCache = MimPluginInfoMemoryCache();
            obj.LinkedDatasetChooserMemoryCache = MimLinkedDatasetChooserMemoryCache(framework_app_def, obj.LinkedDatasetRecorder, obj.PluginInfoMemoryCache);
            obj.ImageDatabase = MimImageDatabase.LoadDatabase(framework_app_def, reporting);
            obj.ImageDatabase.Rebuild([], false, framework_app_def, reporting);
        end
    end
    
end
