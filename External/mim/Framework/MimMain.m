classdef MimMain < CoreBaseClass
    % MimMain. Imports and provides access to data from the TD MIM Toolkit
    %
    %     MimMain provides access to data from the TD MIM Toolkit, and allows 
    %     you to import new data. Data is accessed through one or more MimDataset
    %     objects. Your code should create a single MimMain object, and then ask
    %     it to create a MimDataset object for each dataset you wish to access. 
    %
    %     MimMain is essentially a class factory for MimDatasets, but shares the 
    %     MimReportingInterface (error/progress reporting) objects between all 
    %     datasets, so you have a single error/progress reporting pipeline for 
    %     your use of the TD MIM Toolkit.
    %
    %     To import a new dataset, construct a PTKImageInfo object with the file
    %     path and file name set to the image file. For DICOM files it is only
    %     necessary to specify the path since all image files in that directory
    %     will be imported. Then call CreateDatasetFromInfo. MimMain will import
    %     the data (if it has not already been imported) and return a new
    %     MimDataset object for that dataset.
    %
    %     To access an existing dataset you can use CreateDatasetFromInfo as
    %     above, or you can use CreateDatasetFromUid to retrieve a dataset which
    %     has peviously been imported, using the UID that was associated with
    %     that dataset.
    %
    %     Example
    %     -------
    %     Replace <image path> and <filenames> with the path and filenames
    %     to your image data.
    %
    %         image_info = PTKImageInfo( <image path>, <filenames>, [], [], [], []);
    %         mim = MimMain();
    %         dataset = mim.CreateDatasetFromInfo(image_info);
    %
    %     You can then obtain results from this dataset, e.g.
    %
    %         results = dataset.GetResult('PluginName');
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        FrameworkAppDef
        FrameworkSingleton
        Reporting          % Object for error and progress reporting
        ReportingWithCache % For the dataset, uses the same object, but warnings and messages are cached so multiple warnings can be displayed together
    end

    methods
        
        function obj = MimMain(framework_app_def, reporting)
            % Creates a new main MIM object using the configuration
            % specified by the supplied framework_app_def object
            obj.FrameworkAppDef = framework_app_def;
            obj.Reporting = reporting;
            obj.ReportingWithCache = MimReportingWithCache(obj.Reporting);
            obj.FrameworkSingleton = MimFrameworkSingleton.GetFrameworkSingleton(framework_app_def, obj.Reporting);
            
            bin_directory = framework_app_def.GetBinDirectory();
            CoreDiskUtilities.CreateDirectoryAndAddPathIfNotExisting(bin_directory);
            files_to_compile = framework_app_def.GetFilesToCompile(reporting);
            obj.FrameworkSingleton.CompileMexFileIfRequired(files_to_compile, bin_directory, obj.Reporting);
        end
        
        function Recompile(obj)
            % Forces recompilation of mex files
            
            bin_directory = obj.FrameworkAppDef.GetBinDirectory();
            files_to_compile = obj.FrameworkAppDef.GetFilesToCompile(obj.Reporting);
            obj.FrameworkSingleton.Recompile(files_to_compile, bin_directory, obj.Reporting);
        end
        
        function RebuildDatabase(obj)
            % Forces rebuilding of the image database
            
            obj.FrameworkSingleton.RebuildDatabase(obj.Reporting);
        end
        
        function DeleteCacheForAllDatasets(obj)
            obj.FrameworkAppDef.GetFrameworkDirectories.DeleteCacheForAllDatasets();
        end
        
        function dataset_uids = FindDataset(obj, dataset_uid_prefix)
            % Searches for the dataset with this uid. If a dataset exactly 
            % matches, this will be returned.
            % Otherwise, the specified string prefix will be matched
            % against all dataset uids in the cache, and if there is a 
            % single match then this will be returned.
            % 
            % Note: it is possible for datasets to exist in
            % the cache but not in the database; this can be fixed by
            % rebuilding the database
            
            if iscell(dataset_uid_prefix)
                dataset_uid_prefix = dataset_uid_prefix{1};
            end
            dataset_exists = (7 == exist(fullfile(obj.FrameworkAppDef.GetFrameworkDirectories.GetFrameworkDatasetCacheDirectory, dataset_uid_prefix), 'dir')) || (7 == exist(fullfile(obj.FrameworkAppDef.GetFrameworkDirectories.GetCacheDirectory, dataset_uid_prefix), 'dir'));
            
            if dataset_exists
                dataset_uids = {dataset_uid_prefix};
            else
                all_uids = obj.FrameworkAppDef.GetFrameworkDirectories().GetUidsOfAllDatasetsInCache();
                matches = strncmp(all_uids, dataset_uid_prefix, length(dataset_uid_prefix));
                dataset_uids = all_uids(matches);
            end
        end

        function dataset = CreateDatasetFromUid(obj, dataset_uid_prefix)
            % Creates a MimDataset object for a dataset specified by the uid. The
            % dataset must already be imported.
            
            dataset_uid = obj.FindDataset(dataset_uid_prefix);
            if isempty(dataset_uid)
                obj.Reporting.Error(MimErrors.UidNotFoundErrorId, 'Cannot find the dataset for this UID. Try importing the image using CreateDatasetFromInfo.');
            elseif numel(dataset_uid) > 1
                obj.Reporting.Error(MimErrors.UidNotFoundErrorId, 'More than one dataset for this UID prefix. Try specifying the complete uid.');
            else
                dataset_uid = dataset_uid{1};
            end
            
            dataset_disk_cache = obj.FrameworkSingleton.GetDatasetApiCache.GetDatasetDiskCache(dataset_uid, obj.Reporting);
            
            image_info = dataset_disk_cache.LoadData(obj.FrameworkAppDef.GetFrameworkConfig.ImageInfoCacheName, obj.Reporting);
            if isempty(image_info)
                obj.Reporting.Error(MimErrors.UidNotFoundErrorId, 'Cannot find the dataset for this UID. Try importing the image using CreateDatasetFromInfo.');
            end
            
            dataset = MimDataset(image_info, dataset_disk_cache, obj.FrameworkSingleton.GetLinkedDatasetChooserMemoryCache, obj.FrameworkSingleton.GetClassFactory, obj.ReportingWithCache);
            
            obj.RunCustomPostLoadFunction(dataset_uid, dataset);
        end
        
        function dataset = CreateDatasetFromInfo(obj, new_image_info)
            % Creates a MimDataset object for a dataset specified by the path,
            % filenames and/or uid specified in a PTKImageInfo object. The dataset is
            % imported from the specified path if it does not already exist.
            [image_info, dataset_disk_cache] = obj.ImportDataFromInfo(new_image_info, obj.Reporting);
            
            obj.FrameworkSingleton.AddToDatabase(image_info.ImageUid, obj.Reporting)

            dataset = MimDataset(image_info, dataset_disk_cache, obj.FrameworkSingleton.GetLinkedDatasetChooserMemoryCache, obj.FrameworkSingleton.GetClassFactory, obj.ReportingWithCache);
            
            obj.RunCustomPostLoadFunction(dataset.GetImageInfo.ImageUid, dataset);
        end
        
        function [uids, patient_ids] = ImportDataRecursive(obj, filename)
            % Identical to ImportData()
            [uids, patient_ids] = obj.ImportData(filename);
        end
        
        function [uids, patient_ids] = ImportData(obj, filename)
            % Imports data into the TD MIM Toolkit so that it can be accessed
            % from the CreateDatasetFromUid() method. The input argument is a string
            % containing the path to the data file to import. If the path points to
            % a single (non-DICOM) file, then only the file will be imported. If the
            % path points to a directory, or to a DICOM file, then all image files in
            % the directory and its subdirectories will be imported.
            
            % Only support a string input
            if ~ischar(filename)
                obj.Reporting.Error('MimMain:FileNotAsExpected', 'The file or directory passed to MimMain.ImportData() is not of the expected type.');
            end
            
            % Adds the files to the image database, which groups them into
            % series
            [uids, patient_ids] = obj.FrameworkSingleton.ImportData(filename, obj.ReportingWithCache);
            
            % Add the necessary files to the cache
            obj.ImportSeries(uids);
            
            % Save changes to the database
            obj.FrameworkSingleton.SaveImageDatabase(obj.Reporting);
            
            % Tell the image database to fire a database changed event. We do this here
            % rather than during the import to prevent multiple events being fired
            obj.FrameworkSingleton.ReportChangesToDatabase;
        end
                
        function RunCustomPostLoadFunction(obj, dataset_uid, dataset)
            % This method is called to run a user-defined function for linking
            % datasets
            
            obj.FrameworkAppDef.NewDatasetLoaded(dataset_uid, dataset, obj.Reporting);
        end
        
        function image_database = GetImageDatabase(obj)
            % Returns the Framework's image database
            image_database = obj.FrameworkSingleton.GetImageDatabase;
        end
        
        function directories = GetDirectories(obj)
            % Returns a MimDirectories object which can be used to query and create framework directories
            directories = obj.FrameworkAppDef.GetFrameworkDirectories;
        end
        
        function DeleteDatasets(obj, series_uids)
            % Deletes the datasets specified by a uid or a cell array of uids
            if isempty(series_uids)
                return;
            end
            
            if ~iscell(series_uids)
                series_uids = {series_uids};
            end
            
            for series_uid_cell = series_uids
                series_uid = series_uid_cell{1};

                dataset_to_delete = [];
                try
                    dataset_to_delete = obj.CreateDatasetFromUid(series_uid);
                catch exc
                    %
                    if MimErrors.IsErrorUidNotFound(exc.identifier)
                        obj.Reporting.ShowMessage('MimMain:UidNotFound', ['Failed to delete dataset because its UID could not be found']);
                    else
                        rethrow exc
                    end
                end
                
                if ~isempty(dataset_to_delete)
                    dataset_to_delete.DeleteCacheForThisDataset();
                    delete(dataset_to_delete);
                end
            end
            
            obj.FrameworkSingleton.GetDatasetApiCache.DeleteSeries(series_uids, obj.Reporting);
            obj.FrameworkSingleton.GetLinkedDatasetChooserMemoryCache.DeleteSeries(series_uids, obj.Reporting);
            obj.GetImageDatabase.DeleteSeries(series_uids, obj.Reporting);
        end
        
        function output = RunScript(obj, script_name, varargin)
            if nargin < 3
                parameters = [];
            end
            try
                script_class = feval(script_name);
                output = script_class.RunScript(obj, obj.Reporting, varargin{:});
            catch ex
                obj.Reporting.Error('MimMain:ScriptFailure', ['The script ' script_name ' failed with the following error: ' ex.message]);
                output = [];
            end
        end
    end
    
    methods (Access = private)
        
        function ImportSeries(obj, uids)
            if ~isempty(uids)
                for series_uid = uids
                    series_info = obj.FrameworkSingleton.GetSeriesInfo(series_uid{1});
                    image_info = series_info.GetImageInfo;
                    obj.ImportDataFromInfo(image_info, obj.Reporting);
                end
            end
        end
    
        function [image_info, dataset_disk_cache] = ImportDataFromInfo(obj, new_image_info, reporting)
            % Imports data into the TD MIM Toolkit so that it can be accessed
            % from the CreateDatasetFromUid() method. The input argument is a
            % PTKImageInfo object containing the path, filenames and file type of
            % the data to import. If you do not know the file type, use the
            % ImportData() method instead.
            
            if isempty(new_image_info.ImageUid)
                [series_uid, study_uid, modality] = MimMain.GetImageUID(new_image_info, reporting);
                new_image_info.ImageUid = series_uid;
                new_image_info.StudyUid = study_uid;
                new_image_info.Modality = modality;
            end
            
            dataset_disk_cache = obj.FrameworkSingleton.GetDatasetApiCache.GetDatasetDiskCache(new_image_info.ImageUid, reporting);
            image_info = dataset_disk_cache.LoadData(obj.FrameworkAppDef.GetFrameworkConfig.ImageInfoCacheName, reporting);
            if isempty(image_info)
                image_info = PTKImageInfo;
            end

            [image_info, anything_changed] = image_info.CopyNonEmptyFields(image_info, new_image_info);
            if (anything_changed)
                dataset_disk_cache.SaveData(obj.FrameworkAppDef.GetFrameworkConfig.ImageInfoCacheName, image_info, reporting);
            end
        end
    end
    
    methods (Static, Access = private)
        
        function [image_uid, study_uid, modality] = GetImageUID(image_info, reporting)
            % We need a unique identifier for each dataset. For DICOM files we use
            % the series instance UID. For other files we hash the full file path.
            
            if ~isempty(image_info.ImageFilenames) && isa(image_info.ImageFilenames{1}, 'CoreFilename')
                first_path = image_info.ImageFilenames{1}.Path;
                first_filename = image_info.ImageFilenames{1}.Name;
            else
                filenames = CoreDiskUtilities.GetDirectoryFileList(image_info.ImagePath, '*');
                first_filename = filenames{1};
                first_path = image_info.ImagePath;
            end
                    
            single_image_info = MimGetSingleImageInfo(first_path, first_filename, image_info.ImageFileFormat, DMDicomDictionary.GroupingDictionary, reporting);
            image_uid = single_image_info.ImageUid;
            study_uid = single_image_info.StudyUid;
            modality = single_image_info.Modality;
        end
    end
end

