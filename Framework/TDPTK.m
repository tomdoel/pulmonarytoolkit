classdef TDPTK < handle
    % TDPTK. Imports and provides access to data from the Pulmonary Toolkit
    %
    %     TDPTK provides access to data from the Pulmonary Toolkit, and allows 
    %     you to import new data. Data is accessed through one or more TDDataset
    %     objects. Your code should create a single TDPTK object, and then ask
    %     it to create a TDDataset object for each dataset you wish to access. 
    %
    %     TDPTK is essentially a class factory for TDDatasets, but shares the 
    %     TDReporting (error/progress reporting) objects between all 
    %     datasets, so you have a single error/progress reporting pipeline for 
    %     your use of the Pulmonary Toolkit.
    %
    %     To import a new dataset, construct a TDImageInfo object with the file
    %     path and file name set to the image file. For DICOM files it is only
    %     necessary to specify the path since all image files in that directory
    %     will be imported. Then call CreateDatasetFromInfo. TDPTK will import
    %     the data (if it has not already been imported) and return a new
    %     TDDataset object for that dataset.
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
    %         image_info = TDImageInfo( <image path>, <filenames>, [], [], [], []);
    %         ptk = TDPTK;
    %         dataset = ptk.CreateDatasetFromInfo(image_info);
    %
    %     You can then obtain results from this dataset, e.g.
    %
    %         airways = dataset.GetResult('TDAirways');
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
        function obj = TDPTK(reporting)
            if nargin == 0
                reporting = TDReportingDefault;
            end
            obj.Reporting = reporting;
            obj.ReportingWithCache = TDReportingWithCache(obj.Reporting);
            obj.FrameworkCache = TDFrameworkCache.LoadCache(obj.Reporting);
            TDCompileMexFiles(obj.FrameworkCache, false, obj.Reporting);            
        end
        
        % Forces recompilation of mex files
        function Recompile(obj)
            TDCompileMexFiles(obj.FrameworkCache, true, obj.Reporting);
        end
        
        % Creates a TDDataset object for a dataset specified by the uid. The
        % dataset must already be imported.
        function dataset = CreateDatasetFromUid(obj, uid)
            disk_cache = TDDiskCache(uid, obj.Reporting);
            image_info = disk_cache.Load(TDSoftwareInfo.ImageInfoCacheName);
            if isempty(image_info)
                obj.Reporting.Error('TDPTK:UidNotFound', 'Cannot find the dataset for this UID. Try importing the image using CreateDatasetFromInfo.');
            end
            
            dataset = TDDataset(image_info, disk_cache, obj.ReportingWithCache);
            
        end

        % Creates a TDDataset object for a dataset specified by the path, 
        % filenames and/or uid specified in a TDImageInfo object. The dataset is
        % imported from the specified path if it does not already exist.
        function dataset = CreateDatasetFromInfo(obj, new_image_info)
            
            if isempty(new_image_info.ImageUid)
                [series_uid, study_uid, modality] = TDPTK.GetImageUID(new_image_info);
                new_image_info.ImageUid = series_uid;
                new_image_info.StudyUid = study_uid;
                new_image_info.Modality = modality;
            end
            disk_cache = TDDiskCache(new_image_info.ImageUid, obj.Reporting);
            image_info = disk_cache.Load(TDSoftwareInfo.ImageInfoCacheName);

            if isempty(image_info)
                image_info = new_image_info;                
                disk_cache.Save(TDSoftwareInfo.ImageInfoCacheName, image_info);
            end
            
            % If the cached info doesn't have the modality, add this
            if isempty(image_info.Modality) && ~isempty(new_image_info.Modality)
                image_info = new_image_info;                
                disk_cache.Save(TDSoftwareInfo.ImageInfoCacheName, image_info);
            end
            
            dataset = TDDataset(image_info, disk_cache, obj.ReportingWithCache);
            
        end
    end
    
    methods (Static)
        
        function results_directory = GetResultsDirectoryAndCreateIfNecessary
            application_directory = TDSoftwareInfo.GetApplicationDirectoryAndCreateIfNecessary;
            results_directory = fullfile(application_directory, TDSoftwareInfo.ResultsDirectoryName);
            if ~exist(results_directory, 'dir')
                mkdir(results_directory);
            end
            
        end
    end
    
    methods (Static, Access = private)
                
        % We need a unique identifier for each dataset. For DICOM files we use
        % the series instance UID. For other files we use the filename, which
        % will fail if two imported images have the same filename
        function [image_uid, study_uid, modality] = GetImageUID(image_info)
            study_uid = [];
            switch(image_info.ImageFileFormat)
                case TDImageFileFormat.Dicom
                    filenames = TDDiskUtilities.GetDirectoryFileList(image_info.ImagePath, '*');
                    first_filename = fullfile(image_info.ImagePath, filenames{1});
                    if (exist(first_filename, 'file') ~= 2)
                       throw(MException('TDPTK:FileNotFound', ['The file ' first_filename ' does not exist']));
                    end
                    
                    try
                        metadata = dicominfo(first_filename);
                    catch exception
                        throw(MException('TDPTK:MetaheaderLoadFail', ['The file ' first_filename ' is not a valid DICOM file']));
                    end
                    image_uid = metadata.SeriesInstanceUID;
                    study_uid = metadata.StudyInstanceUID;
                    modality = metadata.Modality;
                case TDImageFileFormat.Metaheader
                    image_uid = image_info.ImageFilenames{1};
                    study_uid = [];
                    modality = [];
                otherwise
                    obj.Reporting.Error('TDPTK:UnknownImageFileFormat', 'Could not import the image because the file format was not recognised.');
            end
            
        end        
    end
end

