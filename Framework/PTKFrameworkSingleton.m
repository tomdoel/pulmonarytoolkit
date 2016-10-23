classdef (Sealed) PTKFrameworkSingleton < handle
    % PTKFrameworkSingleton. The singleton used by all instances of PTKMain
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the Pulmonary Toolkit.
    %
    %     Some parts of the PTK framework (such as the image database) rely on
    %     in-memory caches. Typically changes will be written to disk when the
    %     caches change, but they will not be reloaded at each operation for
    %     efficiency reasons. This would cause inconsistencies if multiple instances
    %     of these classes were running simultaneously.
    %
    %     To prevent this, cached information is held in a singleton class which all
    %     instances of PTKMain get access to.
    %
    %     PTKFrameworkSingleton is a singleton. It cannot be created using the
    %     constructor; instead call PTKFrameworkSingleton.GetFrameworkSingleton;
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        ImageDatabase      % Database of image files
        MexCache     % Information about mex files which is cached on disk
        LinkedDatasetRecorder
        DatasetMemoryCache % Stores PTKDatasetDiskCache objects in memory
        LinkedDatasetChooserMemoryCache
        PluginInfoMemoryCache % Stores parsed plugin classes in memory
    end
        
    methods (Static)
        function framework_singleton = GetFrameworkSingleton(context_def, reporting)
            persistent FrameworkSingleton
            if isempty(FrameworkSingleton) || ~isvalid(FrameworkSingleton)
                FrameworkSingleton = PTKFrameworkSingleton(context_def, reporting);
            end
            framework_singleton = FrameworkSingleton;
        end
    end
    
    methods
        function CompileMexFileIfRequired(obj, files_to_compile, output_directory, reporting)
            % Recompiles mex files if they have changed
            if ~isdeployed
                CoreCompileMexFiles(obj.MexCache, output_directory, files_to_compile, false, ' Run PTKMain.Recompile() to force recompilation.', reporting);
            end
        end
        
        function Recompile(obj, files_to_compile, output_directory, reporting)
            % Forces recompilation of mex files
            
            if ~isdeployed
                CoreCompileMexFiles(obj.MexCache, output_directory, files_to_compile, true, ' Run PTKMain.Recompile() to force recompilation.', reporting);
            end
        end
        
        function RebuildDatabase(obj, reporting)
            obj.ImageDatabase.Rebuild([], true, reporting)
        end
    
        function AddToDatabase(obj, image_uid, reporting)
            
            % CreateDatasetFromInfo() can import new data, so we may need to add
            % to the image database
            if ~obj.ImageDatabase.SeriesExists(image_uid)
                obj.ImageDatabase.Rebuild({image_uid}, false, reporting);
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
        
        function uids = ImportData(obj, filename, reporting)
            uids = PTKImageImporter(filename, obj.ImageDatabase, reporting);
        end
        
        function image_database = GetImageDatabase(obj)
            image_database = obj.ImageDatabase;
        end
        
        function linked_recorder = GetLinkedDatasetRecorder(obj)
            linked_recorder = obj.LinkedDatasetRecorder;
        end
        
        function dataset_memory_cache = GetDatasetMemoryCache(obj)
            dataset_memory_cache = obj.DatasetMemoryCache;
        end
        
        function linked_recorder_memory_cache = GetLinkedDatasetChooserMemoryCache(obj)
            linked_recorder_memory_cache = obj.LinkedDatasetChooserMemoryCache;
        end
        
        function plugin_info_memory_cache = GetPluginInfoMemoryCache(obj)
            plugin_info_memory_cache = obj.PluginInfoMemoryCache;
        end        
    end
    
    methods (Access = private)
        function obj = PTKFrameworkSingleton(context_def, reporting)
            obj.MexCache = PTKFrameworkCache.LoadCache(reporting);
            obj.LinkedDatasetRecorder = PTKLinkedDatasetRecorder.Load(reporting);
            obj.DatasetMemoryCache = PTKDatasetMemoryCache;
            obj.PluginInfoMemoryCache = PTKPluginInfoMemoryCache;
            obj.LinkedDatasetChooserMemoryCache = PTKLinkedDatasetChooserMemoryCache(context_def, obj.LinkedDatasetRecorder, obj.PluginInfoMemoryCache);
            obj.ImageDatabase = PTKImageDatabase.LoadDatabase(reporting);
            obj.ImageDatabase.Rebuild([], false, reporting);
        end
    end
    
end
