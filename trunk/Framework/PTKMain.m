classdef PTKMain < handle
    % PTKMain. Imports and provides access to data from the Pulmonary Toolkit
    %
    %     PTKMain provides access to data from the Pulmonary Toolkit, and allows 
    %     you to import new data. Data is accessed through one or more PTKDataset
    %     objects. Your code should create a single PTKMain object, and then ask
    %     it to create a PTKDataset object for each dataset you wish to access. 
    %
    %     PTKMain is essentially a class factory for PTKDatasets, but shares the 
    %     PTKReporting (error/progress reporting) objects between all 
    %     datasets, so you have a single error/progress reporting pipeline for 
    %     your use of the Pulmonary Toolkit.
    %
    %     To import a new dataset, construct a PTKImageInfo object with the file
    %     path and file name set to the image file. For DICOM files it is only
    %     necessary to specify the path since all image files in that directory
    %     will be imported. Then call CreateDatasetFromInfo. PTKMain will import
    %     the data (if it has not already been imported) and return a new
    %     PTKDataset object for that dataset.
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
    %         ptk = PTKMain;
    %         dataset = ptk.CreateDatasetFromInfo(image_info);
    %
    %     You can then obtain results from this dataset, e.g.
    %
    %         airways = dataset.GetResult('PTKAirways');
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        FrameworkCache
        Reporting          % Object for error and progress reporting
        ReportingWithCache % For the dataset, uses the same object, but warnings and messages are cached so multiple warnings can be displayed together
    end

    methods
        
        % Constructor. If no error/progress reporting object is specified then a
        % default object is created.
        function obj = PTKMain(reporting)
            if nargin == 0
                reporting = PTKReportingDefault;
            end
            obj.Reporting = reporting;
            obj.ReportingWithCache = PTKReportingWithCache(obj.Reporting);
            obj.FrameworkCache = PTKFrameworkCache.LoadCache(obj.Reporting);
            PTKCompileMexFiles(obj.FrameworkCache, false, obj.Reporting);
        end
        
        % Forces recompilation of mex files
        function Recompile(obj)
            PTKCompileMexFiles(obj.FrameworkCache, true, obj.Reporting);
        end
        
        % Creates a PTKDataset object for a dataset specified by the uid. The
        % dataset must already be imported.
        function dataset = CreateDatasetFromUid(obj, dataset_uid)
            dataset_disk_cache = PTKDatasetDiskCache(dataset_uid, obj.Reporting);
            image_info = dataset_disk_cache.LoadData(PTKSoftwareInfo.ImageInfoCacheName, obj.Reporting);
            if isempty(image_info)
                obj.Reporting.Error('PTKMain:UidNotFound', 'Cannot find the dataset for this UID. Try importing the image using CreateDatasetFromInfo.');
            end
            
            dataset = PTKDataset(image_info, dataset_disk_cache, obj.ReportingWithCache);
            
            obj.RunLinkFile(dataset_uid, dataset);
        end
        
        % Creates a PTKDataset object for a dataset specified by the path, 
        % filenames and/or uid specified in a PTKImageInfo object. The dataset is
        % imported from the specified path if it does not already exist.
        function dataset = CreateDatasetFromInfo(obj, new_image_info)
            [image_info, dataset_disk_cache] = PTKMain.ImportDataFromInfo(obj, new_image_info);
            dataset = PTKDataset(image_info, dataset_disk_cache, obj.ReportingWithCache);
            
            obj.RunLinkFile(dataset.GetImageInfo.ImageUid, dataset);
        end
        
        function uids = ImportDataRecursive(obj, filename)
            obj.Reporting.ShowProgress('Imorting data');
            exist_result = exist(filename, 'file');
            
            if exist_result == 0
                % Directory does not exist
                obj.Reporting.Error('PTKMain:DirectoryDoesNotExist', 'The directory passed to PTKMain.ImportDataRecursive() does not exist.');
            
            elseif exist_result == 7
                % Directory specified
                directories_to_do = {filename};
                
            elseif exist_result == 2
                % File specified - try to extract a directory
                [dir_path, ~, ~] = fileparts(filename);
                exist_result_2 = exist(dir_path, 'file');
                if exist_result_2 ~= 0
                    obj.Reporting.Error('PTKMain:DirectoryDoesNotExist', 'The argument passed to PTKMain.ImportDataRecursive() does not exist or is not a directory.');
                else
                    directories_to_do = {dir_path};
                end
            end
            
            uids = {};
            while ~isempty(directories_to_do)
                current_dir = directories_to_do{end};
                directories_to_do(end) = [];
                
                obj.Reporting.UpdateProgressMessage(['Importing data from: ' current_dir]);
                
                if obj.Reporting.HasBeenCancelled
                    obj.Reporting.Error(PTKSoftwareInfo.CancelErrorId, 'User cancelled');
                end
                
                new_uids = obj.ImportData(current_dir);
                uids = cat(2, uids, new_uids);
                next_dirs = PTKDiskUtilities.GetListOfDirectories(current_dir);
                for dir_to_add = next_dirs
                    new_dir = fullfile(current_dir, dir_to_add{1});
                    directories_to_do{end + 1} = new_dir;
                end
            end
            
            obj.Reporting.CompleteProgress;
        end

        
        % Imports data into the Pulmonary Toolkit so that it can be accessed
        % from the CreateDatasetFromUid() method. The input argument is a string
        % containing the path to the data file to import. If the path points to
        % a single (non-DICOM) file, then only the file will be imported. If the
        % path points to a directory, or to a DICOM file, then all image files in
        % the directory will be imported.
        function uids = ImportData(obj, filename)
            uids = {};
            
            % Only support a string input
            if ~ischar(filename)
                obj.Reporting.Error('PTKMain:FileNotAsExpected', 'The file or directory passed to PTKMain.ImportData() is not of the expected type.');
            end
            
            import_whole_directory = false;
            dicom_filenames = {};
            non_dicom_filenames = {};
            
            % Find out file type. 0=does not exist; 2=file; 7-directory
            exist_result = exist(filename, 'file');
            if exist_result == 0
                obj.Reporting.Error('PTKMain:FileDoesNotExist', 'The file or directory passed to PTKMain.ImportData() does not exist.');
                
            elseif exist_result == 7
                import_whole_directory = true;
                [import_folder, ~] = PTKDiskUtilities.GetFullFileParts(filename);
                
            elseif exist_result == 2
                [import_folder, filename_only] = PTKDiskUtilities.GetFullFileParts(filename);
                if isdicom(filename)
                    import_whole_directory = true;
                else
                    import_whole_directory = false;
                    non_dicom_filenames = {filename_only};
                end
            else
                obj.Reporting.Error('PTKMain:FileDoesNotExist', 'The file or directory passed to PTKMain.ImportData() does not exist.');
            end
            
            if import_whole_directory
                all_filenames = PTKTextUtilities.SortFilenames(PTKDiskUtilities.GetDirectoryFileList(import_folder, '*'));
                dicom_filenames = PTKDiskUtilities.RemoveNonDicomFiles(import_folder, all_filenames);
                non_dicom_filenames = setdiff(all_filenames, dicom_filenames);
            end
            
            if ~isempty(dicom_filenames)
                image_info_dicom = PTKImageInfo(import_folder, dicom_filenames, PTKImageFileFormat.Dicom, [], [], []);
                try
                    [image_info_dicom, ~] = PTKMain.ImportDataFromInfo(obj, image_info_dicom);
                    uids{end + 1} = image_info_dicom.ImageUid;
                catch ex
                    obj.Reporting.ShowWarning('PTKMain:DicomReadFail', ['The file ' fullfile(import_folder, dicom_filenames{1}) ' looks like a Dicom file, but I am unable to read it. I will ignore this file.'], ex.message);
                end
            end
            
            while ~isempty(non_dicom_filenames)
                next_filename = non_dicom_filenames{1};
                non_dicom_filenames(1) = [];
                [image_type, principal_filename, secondary_filenames] = PTKDiskUtilities.GuessFileType(import_folder, next_filename, [], obj.Reporting);
                
                % Remove duplicate filenames (which can happen when loading
                % metadata files which have raw and metaheader files)
                non_dicom_filenames = setdiff(non_dicom_filenames, principal_filename);
                non_dicom_filenames = setdiff(non_dicom_filenames, secondary_filenames);
                
                if isempty(image_type)
                    obj.Reporting.ShowWarning('PTKMain:UnableToDetermineImageType', ['Unable to determine image type for ' fullfile(import_folder, next_filename)], []);
                else
                    image_info_nondicom = PTKImageInfo(import_folder, principal_filename, image_type, [], [], []);
                    [image_info_nondicom, ~] = PTKMain.ImportDataFromInfo(obj, image_info_nondicom);
                    uids{end + 1} = image_info_nondicom.ImageUid;
                end
            end
            if numel(uids) == 1
                uids = uids{1};
            end
        end
        
        function RunLinkFile(obj, dataset_uid, dataset)
            user_path = PTKDirectories.GetUserPath;
            if PTKDiskUtilities.FileExists(user_path, 'PTKLinkDatasets.m');
                PTKLinkDatasets(obj, dataset_uid, dataset, obj.Reporting);
            end
        end
        
    end
    
    methods (Static, Access = private)
        
        % Imports data into the Pulmonary Toolkit so that it can be accessed
        % from the CreateDatasetFromUid() method. The input argument is a
        % PTKImageInfo object containing the path, filenames and file type of
        % the data to import. If you do not know the file type, use the
        % ImportData() method instead.
        function [image_info, dataset_disk_cache] = ImportDataFromInfo(obj, new_image_info)
            
            if isempty(new_image_info.ImageUid)
                [series_uid, study_uid, modality] = PTKMain.GetImageUID(new_image_info, obj.Reporting);
                new_image_info.ImageUid = series_uid;
                new_image_info.StudyUid = study_uid;
                new_image_info.Modality = modality;
            end
            
            dataset_disk_cache = PTKDatasetDiskCache(new_image_info.ImageUid, obj.Reporting);
            image_info = dataset_disk_cache.LoadData(PTKSoftwareInfo.ImageInfoCacheName, obj.Reporting);
            if isempty(image_info)
                image_info = PTKImageInfo;
            end

            [image_info, anything_changed] = image_info.CopyNonEmptyFields(image_info, new_image_info);
            if (anything_changed)
                dataset_disk_cache.SaveData(PTKSoftwareInfo.ImageInfoCacheName, image_info, obj.Reporting);
            end
        end
        
                
        % We need a unique identifier for each dataset. For DICOM files we use
        % the series instance UID. For other files we use the filename, which
        % will fail if two imported images have the same filename
        function [image_uid, study_uid, modality] = GetImageUID(image_info, reporting)
            study_uid = [];
            switch(image_info.ImageFileFormat)
                case PTKImageFileFormat.Dicom
                    filenames = PTKDiskUtilities.GetDirectoryFileList(image_info.ImagePath, '*');
                    first_filename = fullfile(image_info.ImagePath, filenames{1});
                    if (exist(first_filename, 'file') ~= 2)
                       throw(MException('PTKMain:FileNotFound', ['The file ' first_filename ' does not exist']));
                    end
                    
                    metadata = PTKDicomUtilities.ReadMetadata(image_info.ImagePath, filenames{1}, reporting);
                    image_uid = metadata.SeriesInstanceUID;
                    study_uid = metadata.StudyInstanceUID;
                    modality = metadata.Modality;
                case PTKImageFileFormat.Metaheader
                    image_uid = image_info.ImageFilenames{1};
                    study_uid = [];
                    modality = [];
                otherwise
                    obj.Reporting.Error('PTKMain:UnknownImageFileFormat', 'Could not import the image because the file format was not recognised.');
            end
        end
        
        
    end
end

