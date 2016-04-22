classdef MimMain < CoreBaseClass
    % MimMain. Imports and provides access to data from the Pulmonary Toolkit
    %
    %     MimMain provides access to data from the Pulmonary Toolkit, and allows 
    %     you to import new data. Data is accessed through one or more MimDataset
    %     objects. Your code should create a single MimMain object, and then ask
    %     it to create a MimDataset object for each dataset you wish to access. 
    %
    %     MimMain is essentially a class factory for MimDatasets, but shares the 
    %     MimReportingInterface (error/progress reporting) objects between all 
    %     datasets, so you have a single error/progress reporting pipeline for 
    %     your use of the Pulmonary Toolkit.
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
    %         mim = MimMain;
    %         dataset = mim.CreateDatasetFromInfo(image_info);
    %
    %     You can then obtain results from this dataset, e.g.
    %
    %         airways = dataset.GetResult('PTKAirways');
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
            
            output_directory = framework_app_def.GetOutputDirectory;
            files_to_compile = framework_app_def.GetFilesToCompile(reporting);
            obj.FrameworkSingleton.CompileMexFileIfRequired(files_to_compile, output_directory, obj.Reporting);
        end
        
        function Recompile(obj)
            % Forces recompilation of mex files
            
            output_directory = obj.FrameworkAppDef.GetOutputDirectory;
            files_to_compile = obj.FrameworkAppDef.GetFilesToCompile(obj.Reporting);
            obj.FrameworkSingleton.Recompile(files_to_compile, output_directory, obj.Reporting);
        end
        
        function RebuildDatabase(obj)
            % Forces rebuilding of the image database
            
            obj.FrameworkSingleton.RebuildDatabase(obj.Reporting);
        end
        
        function dataset_exists = DatasetExists(obj, dataset_uid)
            % Returns true if the dataset specified by the uid is found in
            % the disk cache. Note it is possible for datasets to exist in
            % the cache but not in the database; this can be fixed by
            % rebuilding the database
            
            dataset_exists = (7 == exist(fullfile(obj.FrameworkAppDef.GetFrameworkDirectories.GetFrameworkDatasetCacheDirectory, dataset_uid), 'dir')) || (7 == exist(fullfile(obj.FrameworkAppDef.GetFrameworkDirectories.GetCacheDirectory, dataset_uid), 'dir'));
        end

        function dataset = CreateDatasetFromUid(obj, dataset_uid)
            % Creates a MimDataset object for a dataset specified by the uid. The
            % dataset must already be imported.
            
            if ~obj.DatasetExists(dataset_uid)
                obj.Reporting.Error(PTKSoftwareInfo.UidNotFoundErrorId, 'Cannot find the dataset for this UID. Try importing the image using CreateDatasetFromInfo.');
            end
            
            dataset_disk_cache = obj.FrameworkSingleton.GetDatasetMemoryCache.GetDatasetDiskCache(dataset_uid, obj.Reporting);
            
            image_info = dataset_disk_cache.LoadData(obj.FrameworkAppDef.GetFrameworkConfig.ImageInfoCacheName, obj.Reporting);
            if isempty(image_info)
                obj.Reporting.Error(PTKSoftwareInfo.UidNotFoundErrorId, 'Cannot find the dataset for this UID. Try importing the image using CreateDatasetFromInfo.');
            end
            
            dataset = MimDataset(image_info, dataset_disk_cache, obj.FrameworkSingleton.GetLinkedDatasetChooserMemoryCache, obj.ReportingWithCache);
            
            obj.RunLinkFile(dataset_uid, dataset);
        end
        
        function dataset = CreateDatasetFromInfo(obj, new_image_info)
            % Creates a MimDataset object for a dataset specified by the path,
            % filenames and/or uid specified in a PTKImageInfo object. The dataset is
            % imported from the specified path if it does not already exist.
            [image_info, dataset_disk_cache] = obj.ImportDataFromInfo(new_image_info, obj.Reporting);
            
            obj.FrameworkSingleton.AddToDatabase(image_info.ImageUid, obj.Reporting)

            dataset = MimDataset(image_info, dataset_disk_cache, obj.FrameworkSingleton.GetLinkedDatasetChooserMemoryCache, obj.ReportingWithCache);
            
            obj.RunLinkFile(dataset.GetImageInfo.ImageUid, dataset);
        end
        
        function uids = ImportDataRecursive(obj, filename)
            % Identical to ImportData()
            uids = obj.ImportData(filename);
        end
        
        function uids = ImportData(obj, filename)
            % Imports data into the Pulmonary Toolkit so that it can be accessed
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
            uids = obj.FrameworkSingleton.ImportData(filename, obj.ReportingWithCache);
            
            % Add the necessary files to the cache
            obj.ImportSeries(uids);
            
            % Save changes to the database
            obj.FrameworkSingleton.SaveImageDatabase(obj.Reporting);
            
            % Tell the image database to fire a database changed event. We do this here
            % rather than during the import to prevent multiple events being fired
            obj.FrameworkSingleton.ReportChangesToDatabase;
        end
                
        function RunLinkFile(obj, dataset_uid, dataset)
            % This method is called to run a user-defined function for linking
            % datasets
            user_path = PTKDirectories.GetUserPath;
            if CoreDiskUtilities.FileExists(user_path, 'PTKLinkDatasets.m');
                PTKLinkDatasets(obj, dataset_uid, dataset, obj.Reporting);
            end
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
                    if PTKSoftwareInfo.IsErrorUidNotFound(exc.identifier)
                        obj.Reporting.ShowMessage('MimMain:UidNotFound', ['Failed to delete dataset because its UID could not be found']);
                    else
                        rethrow exc
                    end
                end
                
                if ~isempty(dataset_to_delete)
                    dataset_to_delete.DeleteCacheForThisDataset;
                    delete(dataset_to_delete);
                end
            end
            
            obj.GetImageDatabase.DeleteSeries(series_uids, obj.Reporting);
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
    
        function uids = ImportFromSeriesGrouper(obj, grouper)
            uids = [];
            dicom_groups = grouper.DicomSeriesGroupings;
            for dicom_group = dicom_groups.values
                uids{end + 1} = obj.ImportDicomFiles(dicom_group{1}.Filenames, obj.Reporting);
            end
            
            non_dicom_group = grouper.NonDicomGrouping;
            non_dicom_uids = obj.ImportNonDicomFiles(non_dicom_group.Filenames, obj.Reporting);
            uids = [uids, non_dicom_uids];
        end
        
        function uids = ImportNonDicomFiles(obj, non_dicom_filenames, reporting)
            uids = {};
            while ~isempty(non_dicom_filenames)
                next_filename = non_dicom_filenames{1};
                non_dicom_filenames(1) = [];
                [image_type, principal_filename, secondary_filenames] = MimGuessFileType(next_filename.Path, next_filename.Name, [], reporting);
                
                % Remove duplicate filenames (which can happen when loading
                % metadata files which have raw and metaheader files)
                non_dicom_filenames = CoreDiskUtilities.FilenameSetDiff(non_dicom_filenames, principal_filename, next_filename.Path);
                non_dicom_filenames = CoreDiskUtilities.FilenameSetDiff(non_dicom_filenames, secondary_filenames, next_filename.Path);
                
                if isempty(image_type)
                    reporting.ShowWarning('MimMain:UnableToDetermineImageType', ['Unable to determine image type for ' fullfile(next_filename.Path, next_filename.FullFile)], []);
                else
                    image_info_nondicom = PTKImageInfo(import_folder, principal_filename, image_type, [], [], []);
                    [image_info_nondicom, ~] = obj.ImportDataFromInfo(image_info_nondicom, reporting);
                    uids{end + 1} = image_info_nondicom.ImageUid;
                end
            end
        end
        
        function uid = ImportDicomFiles(obj, dicom_filenames, reporting)
            uid = [];
            image_info_dicom = PTKImageInfo(dicom_filenames{1}.Path, dicom_filenames, MimImageFileFormat.Dicom, [], [], []);
            try
                tic
                [image_info_dicom, ~] = obj.ImportDataFromInfo(image_info_dicom, reporting);
                toc
                uid = image_info_dicom.ImageUid;
            catch ex
                reporting.ShowWarning('MimMain:DicomReadFail', ['The file ' dicom_filenames{1}.FullFile ' looks like a Dicom file, but I am unable to read it. I will ignore this file.'], ex.message);
            end
        end
        
        function [image_info, dataset_disk_cache] = ImportDataFromInfo(obj, new_image_info, reporting)
            % Imports data into the Pulmonary Toolkit so that it can be accessed
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
            
            dataset_disk_cache = obj.FrameworkSingleton.GetDatasetMemoryCache.GetDatasetDiskCache(new_image_info.ImageUid, reporting);
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
            % the series instance UID. For other files we use the filename, which
            % will fail if two imported images have the same filename
            study_uid = [];
            switch(image_info.ImageFileFormat)
                case MimImageFileFormat.Dicom
                    if ~isempty(image_info.ImageFilenames) && isa(image_info.ImageFilenames{1}, 'CoreFilename')
                        first_path = image_info.ImageFilenames{1}.Path;
                        first_filename = image_info.ImageFilenames{1}.Name;
                        full_first_filename = image_info.ImageFilenames{1}.FullFile;
                    else
                        filenames = CoreDiskUtilities.GetDirectoryFileList(image_info.ImagePath, '*');
                        first_filename = filenames{1};
                        first_path = image_info.ImagePath;
                        full_first_filename = fullfile(image_info.ImagePath, filenames{1});
                    end
                    if (exist(full_first_filename, 'file') ~= 2)
                       throw(MException('MimMain:FileNotFound', ['The file ' first_filename ' does not exist']));
                    end
                    
                    metadata = DMUtilities.ReadGroupingMetadata(fullfile(first_path, first_filename), reporting);
                    image_uid = metadata.SeriesInstanceUID;
                    study_uid = metadata.StudyInstanceUID;
                    modality = metadata.Modality;
                case {MimImageFileFormat.Metaheader, MimImageFileFormat.Analyze, MimImageFileFormat.Gipl, ...
                        MimImageFileFormat.Isi, MimImageFileFormat.Nifti, MimImageFileFormat.V3d, ...
                        MimImageFileFormat.Vmp, MimImageFileFormat.Xif, MimImageFileFormat.Vtk, ...        % Visualization Toolkit (VTK)
                        MimImageFileFormat.MicroCT, MimImageFileFormat.Par}
                        
                    image_uid = DMUtilities.GetIdentifierFromFilename(image_info.ImageFilenames{1});
                    study_uid = [];
                    modality = [];
                otherwise
                    obj.Reporting.Error('MimMain:UnknownImageFileFormat', 'Could not import the image because the file format was not recognised.');
            end
        end
        
        
    end
end

