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
    end
    
    methods
        function obj = MimDirectories(config)
            obj.Config = config;
        end
     
        function cache_directory = GetCacheDirectory(obj)
            % Get the parent folder in which dataset cache folders are stored
            
            application_directory = PTKDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            cache_directory = obj.Config.DiskCacheFolderName;
            cache_directory = fullfile(application_directory, cache_directory);
        end
        
        function cache_directory = GetFrameworkDatasetCacheDirectory(obj)
            % Get the parent folder in which framework cache folders for each dataset are stored
            
            application_directory = PTKDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            cache_directory = obj.Config.FrameworkDatasetCacheFolderName;
            cache_directory = fullfile(application_directory, cache_directory);
        end

        function edited_results_directory = GetEditedResultsDirectoryAndCreateIfNecessary(obj)
            % Returns the full path to the directory used for storing results
            
            application_directory = PTKDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            edited_results_directory = fullfile(application_directory, obj.Config.EditedResultsDirectoryName);
            CoreDiskUtilities.CreateDirectoryIfNecessary(edited_results_directory);
        end

        function manual_segmentations_directory = GetManualSegmentationDirectoryAndCreateIfNecessary(obj)
            % Returns the full path to the directory used for storing manual segmentations
            
            application_directory = PTKDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            manual_segmentations_directory = fullfile(application_directory, obj.Config.ManualSegmentationsDirectoryName);
            CoreDiskUtilities.CreateDirectoryIfNecessary(manual_segmentations_directory);
        end
        
        function markers_directory = GetMarkersDirectoryAndCreateIfNecessary(obj)
            % Returns the full path to the directory used for storing marker points
            
            application_directory = PTKDirectories.GetApplicationDirectoryAndCreateIfNecessary;
            markers_directory = fullfile(application_directory, obj.Config.MarkersDirectoryName);
            CoreDiskUtilities.CreateDirectoryIfNecessary(markers_directory);
        end
        
        function uids = GetUidsOfAllDatasetsInCache(obj)
            uids_1 = MimDirectories.GetUidsOfAllDatasetsInFolder(obj.GetCacheDirectory);
            uids_2 = MimDirectories.GetUidsOfAllDatasetsInFolder(obj.GetFrameworkDatasetCacheDirectory);
            uids = unique([uids_1, uids_2]);
        end
        
    end
    
    methods (Static, Access = private)
        function uids = GetUidsOfAllDatasetsInFolder(folder)
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

