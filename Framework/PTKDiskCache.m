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
        function obj = PTKDiskCache(cache_parent_directory, uuid, reporting)
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

            if obj.Exists(PTKSoftwareInfo.SchemaCacheName, [], reporting)
                schema = obj.Load(PTKSoftwareInfo.SchemaCacheName, [], reporting);
                if (schema ~= obj.SchemaNumber)
                    reporting.Error('PTKDiskCache:BadSchema', 'Wrong schema found This is caused by having a disk cache from a redundant version of code. Delete your Temp directory to fix.');
                end
            else
               obj.Save(PTKSoftwareInfo.SchemaCacheName, obj.SchemaNumber, [], reporting);
            end
        end
        
        % Determine if a results file exists in the cahce
        function exists = Exists(obj, name, context, ~)
            filename = [fullfile(obj.CachePath, char(context), name) '.mat'];
            exists = exist(filename, 'file');
        end
        
        % Determine if the raw image file associated with a PTKImage results file exists in the cahce
        function exists = RawFileExists(obj, name, context, ~)
            filename = [fullfile(obj.CachePath, char(context), name) '.raw'];
            exists = exist(filename, 'file');
        end

        % Load a result from the cache
        function [result, info] = Load(obj, name, context, reporting)
            if obj.Exists(name, context, reporting)
                file_path = fullfile(obj.CachePath, char(context));
                
                try
                    results_struct = PTKDiskUtilities.LoadStructure(file_path, name, reporting);
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
                
                result = results_struct.value;

                % Return a cacheinfo object, if one was requested
                if (nargout > 1)
                    if isfield(results_struct, 'info')
                        info = results_struct.info;
                    else
                        info = [];
                    end
                end
                
            else
               result = []; 
               info = [];
            end
        end
        
        
        % Save a result to the cache
        function Save(obj, name, value, context, reporting)
            obj.PrivateSave(name, value, [], context, reporting);
        end

        % Save a result to the cache
        function SaveWithInfo(obj, name, value, info, context, reporting)
            obj.PrivateSave(name, value, info, context, reporting);
        end
        
        % Remove all results files for this dataset. Does not remove certain
        % files such as dataset info and manually-created marker files, unless
        % the "remove_framework_files" flag is set to true.
        function RemoveAllCachedFiles(obj, remove_framework_files, reporting)
            
            % Switch on recycle bin before deleting
            state = recycle;
            recycle('on');
            
            % Remove cache files in the root directory for this dataset
            obj.RemoveFilesInDirectory(obj.CachePath, remove_framework_files, reporting);
            
            % Remove cache files in the context directories for this dataset
            dir_list = PTKDiskUtilities.GetListOfDirectories(obj.CachePath);
            for next_dir = dir_list
                obj.RemoveFilesInDirectory(fullfile(obj.CachePath, next_dir{1}), remove_framework_files, reporting);
            end
            
            % Restore previous recycle bin state
            recycle(state);
        end
        
    end
        
    methods (Static, Access = private)
    
        function RemoveFilesInDirectory(file_path, remove_framework_files, reporting)
            
            file_list = PTKDiskUtilities.GetDirectoryFileList(file_path, '*.raw');
            file_list_2 = PTKDiskUtilities.GetDirectoryFileList(file_path, '*.mat');
            file_list = cat(2, file_list, file_list_2);
            for index = 1 : length(file_list)
                file_name = file_list{index};
                is_framework_file = PTKDirectories.IsFrameworkFile(file_name);
                if (remove_framework_files || (~is_framework_file))
                    full_filename = fullfile(file_path, file_name);
                    reporting.ShowMessage('PTKDiskCache:RecyclingCacheDirectory', ['Moving cache file to recycle bin: ' full_filename]);
                    
                    delete(full_filename);
                    reporting.Log(['Deleting ' full_filename]);
                end
            end
        end
    end
    
    methods (Access = private)

        function PrivateSave(obj, name, value, info, context, reporting)
            file_path_with_context = fullfile(obj.CachePath, char(context));
            PTKDiskUtilities.CreateDirectoryIfNecessary(file_path_with_context);
            result = [];
            if ~isempty(info)
                result.info = info;
            end
            result.value = value;
            PTKDiskUtilities.SaveStructure(file_path_with_context, name, result, reporting);
        end
    end
end