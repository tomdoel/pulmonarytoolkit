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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties (SetAccess = private)
        CachePath    % The path where cache files will be stored for this dataset
    end
    
    properties (Access = private)
        Uuid         % A unique identifier for this dataset
        SchemaNumber % Version number
        Reporting
    end
    
    methods
        
        function obj = PTKDiskCache(cache_parent_directory, uuid, reporting)
            obj.SchemaNumber = 1;
            obj.Uuid = uuid;
            obj.Reporting = reporting;
            
            % Create a disk cache object, and associated folder, for the dataset
            % associated with this unique identifier
            if ~exist(cache_parent_directory, 'dir')
                mkdir(cache_parent_directory);
            end
            
            obj.CachePath = fullfile(cache_parent_directory, uuid);
            if obj.CacheDirExists
                reporting.LogVerbose(['Using disk cache : ' obj.CachePath]);
                if obj.Exists(PTKSoftwareInfo.SchemaCacheName, [], reporting)
                    schema = obj.Load(PTKSoftwareInfo.SchemaCacheName, [], reporting);
                    if (schema ~= obj.SchemaNumber)
                        reporting.Error('PTKDiskCache:BadSchema', 'Wrong schema found. This is caused by having a disk cache from a redundant version of code. Delete your cache directory to fix.');
                    end
                else
                    obj.Save(PTKSoftwareInfo.SchemaCacheName, obj.SchemaNumber, [], reporting);
                end
                
            end
        end
        
        function exists = Exists(obj, name, context, ~)
            if ~obj.CacheDirExists
                exists = false;
            else
                % Determine if a results file exists in the cahce
                filename = [fullfile(obj.CachePath, char(context), name) '.mat'];
                exists = (2 == exist(filename, 'file'));
            end
        end
        
        function DeleteCacheFile(obj, name, context, reporting)
            % Deletes the header and raw file from this cache
            if obj.CacheDirExists
                
                % Store the state of the recycle bin
                state = recycle;
                
                % Set recycle to on or off depending on a software switch
                if PTKSoftwareInfo.RecycleWhenDeletingCacheFiles
                    recycle('on');
                else
                    recycle('off');
                end
                
                % Determine if a results file exists in the cahce
                mat_filename = [fullfile(obj.CachePath, char(context), name) '.mat'];
                if (2 == exist(mat_filename, 'file'))
                    reporting.Log(['Deleting cache file: ' mat_filename]);
                    delete(mat_filename);
                end
                raw_filename = [fullfile(obj.CachePath, char(context), name) '.raw'];
                if (2 == exist(raw_filename, 'file'))
                    reporting.Log(['Deleting cache file: ' raw_filename]);
                    delete(raw_filename);
                end
                
                % Restore previous recycle bin state
                recycle(state);
            end
        end
        
        function exists = RawFileExists(obj, name, context, ~)
            if ~obj.CacheDirExists
                exists = false;
            else
                % Determine if the raw image file associated with a PTKImage results file exists in the cahce
                filename = [fullfile(obj.CachePath, char(context), name) '.raw'];
                exists = (2 == exist(filename, 'file'));
            end
        end

        function [result, info] = Load(obj, name, context, reporting)
            % Load a result from the cache
            if obj.CacheDirExists && obj.Exists(name, context, reporting)
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
        
        function Save(obj, name, value, context, reporting)
            % Save a result to the cache
            
            obj.PrivateSave(name, value, [], context, reporting);
        end

        function SaveWithInfo(obj, name, value, info, context, reporting)
            % Save a result to the cache
            
            obj.PrivateSave(name, value, info, context, reporting);
        end
        
        function Delete(obj, reporting)
            % Deletes the disk cache
            
            if obj.CacheDirExists
                % Store the state of the recycle bin
                state = recycle;
                
                % Set recycle to on or off depending on a software switch
                if PTKSoftwareInfo.RecycleWhenDeletingCacheFiles
                    recycle('on');
                else
                    recycle('off');
                end
                
                reporting.ShowMessage('PTKDiskCache:DeletingDirectory', ['Deleting directory: ' obj.CachePath]);
                reporting.Log(['Deleting directory' obj.CachePath]);
                rmdir(obj.CachePath, 's');
                
                % Restore previous recycle bin state
                recycle(state);
            end
        end

        
        function RemoveAllCachedFiles(obj, remove_framework_files, reporting)
            % Remove all results files for this dataset. Does not remove certain
            % files such as dataset info and manually-created marker files, unless
            % the "remove_framework_files" flag is set to true.
            
            if obj.CacheDirExists
                % Store the state of the recycle bin
                state = recycle;
                
                % Set recycle to on or off depending on a software switch
                if PTKSoftwareInfo.RecycleWhenDeletingCacheFiles
                    recycle('on');
                else
                    recycle('off');
                end
                
                % Remove cache files in the root directory for this dataset
                obj.RemoveFilesInDirectory(obj.CachePath, '*', remove_framework_files, reporting);
                
                % Remove cache files in the context directories for this dataset
                dir_list = CoreDiskUtilities.GetListOfDirectories(obj.CachePath);
                for next_dir = dir_list
                    obj.RemoveFilesInDirectory(fullfile(obj.CachePath, next_dir{1}), '*', remove_framework_files, reporting);
                end
                
                % Restore previous recycle bin state
                recycle(state);
            end
        end
        
        function dir_list = DeleteFileForAllContexts(obj, name, reporting)
            % Delete particular files from all context folders in this dataset
            
            if obj.CacheDirExists
                % Remove cache files in the root directory for this dataset
                obj.RemoveFilesInDirectory(obj.CachePath, name, false, reporting);
                
                % Remove cache files in the context directories for this dataset
                dir_list = CoreDiskUtilities.GetListOfDirectories(obj.CachePath);
                for next_dir = dir_list
                    obj.RemoveFilesInDirectory(fullfile(obj.CachePath, next_dir{1}), name, false, reporting);
                end
            end
        end
        
        function file_list = GetAllFilesInCache(obj)
            file_list = CorePair.empty;

            if obj.CacheDirExists
                context_list = CoreDiskUtilities.GetListOfDirectories(obj.CachePath);
                context_list{end + 1} = '';
                for context_cell = context_list
                    context = context_cell{1};
                    m_file_list = CoreDiskUtilities.GetDirectoryFileList(fullfile(obj.CachePath, context), '*.mat');
                    for m_file = m_file_list
                        [~, name, ~] = fileparts(m_file{1});
                        file_list{end + 1} = CorePair(context, name);
                    end
                end
            end
        end

    end
        
    methods (Static, Access = private)
    
        function RemoveFilesInDirectory(file_path, name, remove_framework_files, reporting)
            
            file_list = CoreDiskUtilities.GetDirectoryFileList(file_path, [name, '.raw']);
            file_list_2 = CoreDiskUtilities.GetDirectoryFileList(file_path, [name, '.mat']);
            file_list = cat(2, file_list, file_list_2);
            for index = 1 : length(file_list)
                file_name = file_list{index};
                is_framework_file = PTKDirectories.IsFrameworkFile(file_name);
                if (remove_framework_files || (~is_framework_file))
                    full_filename = fullfile(file_path, file_name);
                    reporting.ShowMessage('PTKDiskCache:RecyclingCacheDirectory', ['Deleting: ' full_filename]);
                    
                    delete(full_filename);
                    reporting.Log(['Deleting ' full_filename]);
                end
            end
        end
    end
    
    methods (Access = private)

        function CreateCacheDirIfNecessary(obj)
            if ~obj.CacheDirExists
                mkdir(obj.CachePath);
                obj.Reporting.LogVerbose(['Creating disk cache : ' obj.CachePath]);
                
                % Create schema
                obj.Save(PTKSoftwareInfo.SchemaCacheName, obj.SchemaNumber, [], obj.Reporting);
            end
        end
        
        function exists = CacheDirExists(obj)
            exists = exist(obj.CachePath, 'dir') == 7;
        end
        
        function PrivateSave(obj, name, value, info, context, reporting)
            obj.CreateCacheDirIfNecessary;
            file_path_with_context = fullfile(obj.CachePath, char(context));
            CoreDiskUtilities.CreateDirectoryIfNecessary(file_path_with_context);
            result = [];
            if ~isempty(info)
                result.info = info;
            end
            result.value = value;
            PTKDiskUtilities.SaveStructure(file_path_with_context, name, result, PTKSoftwareInfo.Compression, reporting);
        end
    end
end