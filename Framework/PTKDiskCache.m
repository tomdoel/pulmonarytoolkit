classdef PTKDiskCache < handle
    % PTKDiskCache. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Used to cache image analysis results for a particular dataset.
    %     This class stores a list of dependencies for a particular plugin 
    %     result, for a particular dataset. Each dependency represents another 
    %     plugin result which was accessed during the generation of this result. 
    %     These are used to ensure that any given result is still valid, by 
    %     ensuring that the dependency list matches the dependencies currently 
    %     held in the cache for each plugin.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties (SetAccess = private)
        CachePath    % The path where cache files will be stored for this dataset
    end
    
    properties (Access = private)
        Uuid         % A unique identifier for this dataset
        SchemaNumber % Version number
    end
    
    methods
        
        % Create a disk cache object, and associated folder, for the dataset
        % associated with this unique identifier
        function obj = PTKDiskCache(uuid, reporting)
            cache_parent_directory = obj.GetCacheDirectory;
            if ~exist(cache_parent_directory, 'dir')
                mkdir(cache_parent_directory);
            end
            
            cache_directory = fullfile(cache_parent_directory, uuid);
            if ~exist(cache_directory, 'dir')
                mkdir(cache_directory);
                reporting.ShowMessage('PTKDiskCache:NewCacheDirectory', ['Creating disk cache : ' cache_directory]);
            else
                reporting.ShowMessage('PTKDiskCache:ExistingCacheDirectory', ['Using disk cache : ' cache_directory]);
            end
            
            obj.Uuid = uuid;
            obj.CachePath = cache_directory;
            obj.SchemaNumber = 1;

            if obj.Exists(PTKSoftwareInfo.SchemaCacheName, reporting)
                schema = obj.Load(PTKSoftwareInfo.SchemaCacheName, reporting);
                if (schema ~= obj.SchemaNumber)
                    reporting.Error('PTKDiskCache:BadSchema', 'Wrong schema found This is caused by having a disk cache from a redundant version of code. Delete your Temp directory to fix.');
                end
            else
               obj.Save(PTKSoftwareInfo.SchemaCacheName, obj.SchemaNumber, reporting);
            end
        end
        
        % Determine if a results file exists in the cahce
        function exists = Exists(obj, name, ~)
            filename = [fullfile(obj.CachePath, name) '.mat'];
            exists = exist(filename, 'file');
        end
        
        % Determine if the raw image file associated with a PTKImage results file exists in the cahce
        function exists = RawFileExists(obj, name, ~)
            filename = [fullfile(obj.CachePath, name) '.raw'];
            exists = exist(filename, 'file');
        end
        
        
        % Load a result from the cache
        function [result, info] = Load(obj, name, reporting)
            if obj.Exists(name, reporting)
                filename = [fullfile(obj.CachePath, name) '.mat'];
                results_struct = load(filename);
                result = results_struct.value;

                % Return a cacheinfo object, if one was requested
                if (nargout > 1)
                    if isfield(results_struct, 'info')
                        info = results_struct.info;
                    else
                        info = [];
                    end
                end
                
                
                % PTKImage files typically have the raw image data stored in a 
                % separate file
                if isa(result, 'PTKImage')
                    try
                        result.LoadRawImage(obj.CachePath, reporting);
                    
                    catch exception
                        
                        % Check for the particular case of the .raw file being
                        % deleted
                        if strcmp(exception.identifier, 'PTKImage:RawFileNotFound')
                            reporting.Log(['Disk cache found a header file with no corresponding raw file for plugin ' name]);
                            result = [];
                            info = [];
                            return;
                        else
                            % For other errors we force an exception
                            rethrow(exception);
                        end
                    end
                end
                
            else
               result = []; 
               info = [];
            end
        end
        
        
        % Save a result to the cache
        function Save(obj, name, value, reporting)
            obj.PrivateSave(name, value, [], reporting);
        end

        % Save a result to the cache
        function SaveWithInfo(obj, name, value, info, reporting)
            obj.PrivateSave(name, value, info, reporting);
        end
        
        % Remove all results files for this dataset. Does not remove certain
        % files such as dataset info and manually-created marker files, unless
        % the "remove_framework_files" flag is set to true.
        function RemoveAllCachedFiles(obj, remove_framework_files, reporting)
            
            % Switch on recycle bin before deleting
            state = recycle;
            recycle('on');
            
            file_list = PTKDiskUtilities.GetDirectoryFileList(obj.CachePath, '*.raw');
            file_list_2 = PTKDiskUtilities.GetDirectoryFileList(obj.CachePath, '*.mat');
            file_list = cat(2, file_list, file_list_2);
            for index = 1 : length(file_list)
                file_name = file_list{index};
                is_framework_file = strcmp(file_name, [PTKSoftwareInfo.SchemaCacheName '.mat']) || strcmp(file_name, [PTKSoftwareInfo.ImageInfoCacheName '.mat']) || strcmp(file_name, [PTKSoftwareInfo.MakerPointsCacheName '.mat']) || strcmp(file_name, [PTKSoftwareInfo.MakerPointsCacheName 'raw']) || strcmp(file_name, [PTKSoftwareInfo.ImageTemplatesCacheName '.mat']);
                if (remove_framework_files || (~is_framework_file))
                    full_filename = fullfile(obj.CachePath, file_name);
                    reporting.ShowMessage('PTKDiskCache:RecyclingCacheDirectory', ['Moving cache file to recycle bin: ' full_filename]);
                    
                    delete(full_filename);
                    reporting.Log(['Deleting ' full_filename]);
                end
            end
            
            % Restore previous recycle bin state
            recycle(state);
        end
        
    end
        
    methods (Static)
        
        % Get the parent folder in which dataset cache folders are stored
        function cache_directory = GetCacheDirectory
            application_directory = PTKSoftwareInfo.GetApplicationDirectoryAndCreateIfNecessary;
            cache_directory = PTKSoftwareInfo.DiskCacheFolderName;
            cache_directory = fullfile(application_directory, cache_directory);
        end
        
        function uids = GetUidsOfAllDatasetsInCache
            cache_directory = PTKDiskCache.GetCacheDirectory;
            subdirectories = PTKDiskUtilities.GetListOfDirectories(cache_directory);
            uids = {};
            for subdir = subdirectories
                candidate_uid = subdir{1};
                if 2 == exist(fullfile(cache_directory, candidate_uid, [PTKSoftwareInfo.ImageInfoCacheName '.mat']), 'file')
                    uids{end+1} = candidate_uid;
                end
            end
        end
    end
    
    methods (Access = private)

        function PrivateSave(obj, name, value, info, reporting)  
            result = [];
            if ~isempty(info)
                result.info = info;
            end
            if isa(value, 'PTKImage')
                reporting.Log(['Saving raw image data for ' name]);
                header = value.SaveRawImage(obj.CachePath, name);
                result.value = header;
            else
                result.value = value;
            end
            reporting.Log(['Saving data for ' name]);
            
            filename = [fullfile(obj.CachePath, name) '.mat'];
            save(filename, '-struct', 'result');
        end        
    end
end