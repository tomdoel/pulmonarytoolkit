classdef MockDatasetDiskCache < handle
    % MockDatasetDiskCache. Part of the PTK test framework
    %
    % This class is used in tests in place of a PTKDatasetDiskCache. It allows
    % expected calls to be verified, while maintaining some of the expected
    % behaviour of a PTKDatasetDiskCache object.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
            
    
    properties (Access = private)
        StoredData
    end
    
    methods
        function obj = MockDatasetDiskCache()
            obj.StoredData = containers.Map;
        end

        function AddEntry(obj, name, value, context)
            obj.StoredData([name char(context)]) = value;
        end
        
        
        
        % Test methods
        
        function [value, cache_info] = LoadPluginResult(obj, plugin_name, context, reporting)
        end
        
        % Stores a plugin result in the disk cache and updates cached dependency
        % information
        function SavePluginResult(obj, plugin_name, result, cache_info, context, reporting)
        end
        
        % Caches Dependency information
        function CachePluginInfo(obj, plugin_name, cache_info, context, reporting)
        end
        
        % Saves additional data associated with this dataset to the cache
        function SaveData(obj, data_filename, value, reporting)
            obj.StoredData(data_filename) = value;
        end
        
        % Loads additional data associated with this dataset from the cache
        function value = LoadData(obj, data_filename, reporting)
        end
        
        function cache_path = GetCachePath(obj, ~)
        end
        
        function RemoveAllCachedFiles(obj, remove_framework_files, reporting)
        end
        
        function exists = Exists(obj, name, context, reporting)
            exists = obj.StoredData.isKey([name char(context)]);
        end

        function valid = CheckDependencyValid(obj, next_dependency, reporting)
        end
    end
end


