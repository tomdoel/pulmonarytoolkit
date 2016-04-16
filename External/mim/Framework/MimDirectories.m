classdef MimDirectories < CoreBaseClass
    % MimDirectories. Helper functions relating to directory use by the MIM
    % toolkit
    %
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
        ParentDirectory
    end
    
    methods
        function obj = MimDirectories(app_parent_directory, config)
            obj.ParentDirectory = app_parent_directory;
            obj.Config = config;
        end
        
        function application_directory = GetApplicationDirectoryAndCreateIfNecessary(obj)
            application_directory = obj.Config.ApplicationSettingsFolderName;
            application_directory = fullfile(obj.ParentDirectory, application_directory);  
            if ~exist(application_directory, 'dir')
                mkdir(application_directory);
            end
        end

        function cache_directory = GetCacheDirectory(obj)
            % Get the parent folder in which dataset cache folders are stored
            
            application_directory = obj.GetApplicationDirectoryAndCreateIfNecessary;
            cache_directory = obj.Config.DiskCacheFolderName;
            cache_directory = fullfile(application_directory, cache_directory);
        end
        
        function cache_directory = GetFrameworkDatasetCacheDirectory(obj)
            % Get the parent folder in which framework cache folders for each dataset are stored
            
            application_directory = obj.GetApplicationDirectoryAndCreateIfNecessary;
            cache_directory = obj.Config.FrameworkDatasetCacheFolderName;
            cache_directory = fullfile(application_directory, cache_directory);
        end

        function edited_results_directory = GetEditedResultsDirectoryAndCreateIfNecessary(obj)
            % Returns the full path to the directory used for storing results
            
            application_directory = obj.GetApplicationDirectoryAndCreateIfNecessary;
            edited_results_directory = fullfile(application_directory, obj.Config.EditedResultsDirectoryName);
            CoreDiskUtilities.CreateDirectoryIfNecessary(edited_results_directory);
        end

        function manual_segmentations_directory = GetManualSegmentationDirectoryAndCreateIfNecessary(obj)
            % Returns the full path to the directory used for storing manual segmentations
            
            application_directory = obj.GetApplicationDirectoryAndCreateIfNecessary;
            manual_segmentations_directory = fullfile(application_directory, obj.Config.ManualSegmentationsDirectoryName);
            CoreDiskUtilities.CreateDirectoryIfNecessary(manual_segmentations_directory);
        end
        
        function markers_directory = GetMarkersDirectoryAndCreateIfNecessary(obj)
            % Returns the full path to the directory used for storing marker points
            
            application_directory = obj.GetApplicationDirectoryAndCreateIfNecessary;
            markers_directory = fullfile(application_directory, obj.Config.MarkersDirectoryName);
            CoreDiskUtilities.CreateDirectoryIfNecessary(markers_directory);
        end
        
        function framework_file_path = GetMexCacheFilePath(obj)
            % Returns the full path to the cache file containing info about compiled mex files 
            
            settings_dir = obj.GetApplicationDirectoryAndCreateIfNecessary;
            cache_filename = obj.Config.MexCacheFileName;
            framework_file_path = fullfile(settings_dir, cache_filename);
        end
        
        function framework_file_path = GetLegacyMexCacheFilePath(obj)
            % Returns the full path to the legacy framework cache file
            
            settings_dir = obj.GetApplicationDirectoryAndCreateIfNecessary;
            cache_filename = 'PTKFrameworkCache.mat';
            framework_file_path = fullfile(settings_dir, cache_filename);
        end
        
        function settings_file_path = GetImageDatabaseFilePath(obj)
            % Returns the full path to the image database file
            
            settings_dir = obj.GetApplicationDirectoryAndCreateIfNecessary;
            cache_filename = obj.Config.ImageDatabaseFileName;
            settings_file_path = fullfile(settings_dir, cache_filename);
        end
        
        function settings_file_path = GetLegacyImageDatabaseFilePath(obj)
            % Returns the full path to the image database file
            
            settings_dir = obj.GetApplicationDirectoryAndCreateIfNecessary;
            cache_filename = 'PTKImageDatabase.mat';
            settings_file_path = fullfile(settings_dir, cache_filename);
        end
        
        function results_directory = GetOutputDirectoryAndCreateIfNecessary(obj)
            % Returns the full path to the directory used for storing results
            
            application_directory = obj.GetApplicationDirectoryAndCreateIfNecessary;
            results_directory = fullfile(application_directory, obj.Config.OutputDirectoryName);
            CoreDiskUtilities.CreateDirectoryIfNecessary(results_directory);
        end
        
        function uids = GetUidsOfAllDatasetsInCache(obj)
            uids_1 = obj.GetUidsOfAllDatasetsInFolder(obj.GetCacheDirectory);
            uids_2 = obj.GetUidsOfAllDatasetsInFolder(obj.GetFrameworkDatasetCacheDirectory);
            uids = unique([uids_1, uids_2]);
        end
        
        function linking_file_path = GetLinkingCacheFilePath(obj)
            % Returns the full path to the linking cache file
            
            settings_dir = obj.GetApplicationDirectoryAndCreateIfNecessary;
            cache_filename = obj.Config.LinkingCacheFileName;
            linking_file_path = fullfile(settings_dir, cache_filename);
        end
    end
    
    methods (Access = private)
        function uids = GetUidsOfAllDatasetsInFolder(obj, folder)
            subdirectories = CoreDiskUtilities.GetListOfDirectories(folder);
            uids = {};
            for subdir = subdirectories
                candidate_uid = subdir{1};
                full_file_name = [folder, filesep, candidate_uid, filesep, obj.Config.ImageInfoCacheName, '.mat'];
                if 2 == exist(full_file_name, 'file')
                    uids{end+1} = candidate_uid;
                end
            end
        end        
    end
end

