classdef TDDiskCache < handle
    % TDDiskCache. Part of the internal framework of the Pulmonary Toolkit.
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
        Reporting     % Error and log reporting
        Uuid         % A unique identifier for this dataset
        SchemaNumber % Version number
    end
    
    methods
        
        % Create a disk cache object, and associated folder, for the dataset
        % associated with this unique identifier
        function obj = TDDiskCache(uuid, reporting)
            obj.Reporting = reporting;
            cache_parent_directory = obj.GetCacheDirectory;
            if ~exist(cache_parent_directory, 'dir')
                mkdir(cache_parent_directory);
            end
            
            cache_directory = fullfile(cache_parent_directory, uuid);
            if ~exist(cache_directory, 'dir')
                mkdir(cache_directory);
                reporting.ShowMessage('TDDiskCache:NewCacheDirectory', ['Creating disk cache : ' cache_directory]);
            else
                reporting.ShowMessage('TDDiskCache:ExistingCacheDirectory', ['Using disk cache : ' cache_directory]);
            end
            
            obj.Uuid = uuid;
            obj.CachePath = cache_directory;
            obj.SchemaNumber = 1;

            if obj.Exists(TDSoftwareInfo.SchemaCacheName)
                schema = obj.Load(TDSoftwareInfo.SchemaCacheName);
                if (schema ~= obj.SchemaNumber)
                    reporting.Error('TDDiskCache:BadSchema', 'Wrong schema found This is caused by having a disk cache from a redundant version of code. Delete your Temp directory to fix.');
                end
            else
               obj.Save(TDSoftwareInfo.SchemaCacheName, obj.SchemaNumber);
            end
        end
        
        % Determine if a results file exists in the cahce
        function exists = Exists(obj, name)
            filename = [fullfile(obj.CachePath, name) '.mat'];
            exists = exist(filename, 'file');
        end
        
        % Determine if the raw image file associated with a TDImage results file exists in the cahce
        function exists = RawFileExists(obj, name)
            filename = [fullfile(obj.CachePath, name) '.raw'];
            exists = exist(filename, 'file');
        end
        
        
        % Load a result from the cache
        function [result, info] = Load(obj, name)
            if obj.Exists(name)
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
                
                
                % TDImage files typically have the raw image data stored in a 
                % separate file
                if isa(result, 'TDImage')
                    try
                        result.LoadRawImage(obj.CachePath, obj.Reporting);
                    
                    catch exception
                        
                        % Check for the particular case of the .raw file being
                        % deleted
                        if strcmp(exception.identifier, 'TDImage:RawFileNotFound')
                            obj.Reporting.Log(['Disk cache found a header file with no corresponding raw file for plugin ' name]);
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
        function Save(obj, name, value, info)  
            result = [];
            if nargin > 3
                result.info = info;
            end
            if isa(value, 'TDImage')
                obj.Reporting.Log(['Saving raw image data for ' name]);
                header = value.SaveRawImage(obj.CachePath, name);
                result.value = header;
            else
                result.value = value;
            end
            obj.Reporting.Log(['Saving data for ' name]);
            
            filename = [fullfile(obj.CachePath, name) '.mat'];
            save(filename, '-struct', 'result');
        end

        
        % Remove all results files for this dataset. Does not remove certain
        % files such as dataset info and manually-created marker files.
        function RemoveAllCachedFiles(obj, reporting)
            
            % Switch on recycle bin before deleting
            state = recycle;
            recycle('on');
            
            file_list = TDDiskUtilities.GetDirectoryFileList(obj.CachePath, '*.raw');
            file_list_2 = TDDiskUtilities.GetDirectoryFileList(obj.CachePath, '*.mat');
            file_list = cat(2, file_list, file_list_2);
            for index = 1 : length(file_list)
                file_name = file_list{index};
                if (~strcmp(file_name, [TDSoftwareInfo.SchemaCacheName '.mat'])) && (~strcmp(file_name, [TDSoftwareInfo.ImageInfoCacheName '.mat'])) && (~strcmp(file_name, [TDSoftwareInfo.MakerPointsCacheName '.mat'])) && (~strcmp(file_name, [TDSoftwareInfo.MakerPointsCacheName 'raw'])) && (~strcmp(file_name, [TDSoftwareInfo.ImageTemplatesCacheName '.mat']))
                    full_filename = fullfile(obj.CachePath, file_name);
                    reporting.ShowMessage('TDDiskCache:RecyclingCacheDirectory', ['Moving cache file to recycle bin: ' full_filename]);
                    
                    delete(full_filename);
                    obj.Reporting.Log(['Deleting ' full_filename]);
                end
            end
            
            % Restore previous recycle bin state
            recycle(state);
        end
        
    end
        
    methods (Static)
        
        % Get the parent folder in which dataset cache folders are stored
        function cache_directory = GetCacheDirectory
            application_directory = TDSoftwareInfo.GetApplicationDirectoryAndCreateIfNecessary;
            cache_directory = TDSoftwareInfo.DiskCacheFolderName;
            cache_directory = fullfile(application_directory, cache_directory);
        end
        
    end
end