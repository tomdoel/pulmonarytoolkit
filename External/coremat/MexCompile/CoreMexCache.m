classdef CoreMexCache < CoreBaseClass
    % CoreMexCache. 
    %
    %     CoreMexCache stores compiled mex file information that needs to
    %     persist between sessions, such as the version numbers of the currently
    %     compiled mex files.
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        MexInfoMap
        IsNewlyCreated
    end
    
    properties (Transient)
        CacheFilename
    end
    
    methods (Static)
        function cache = LoadCache(cacheFilename, reporting)
            try
                if exist(cacheFilename, 'file')                    
                    cache = CoreLoadXml(cacheFilename, reporting);
                    cache = cache.Cache;
                    cache.IsNewlyCreated = false;
                    cache.CacheFilename = cacheFilename;
                else
                    reporting.ShowWarning('CoreMexCache:MexCacheFileNotFound', 'No mex cache file found. Will create new one on exit', []);
                    cache = CoreMexCache(cacheFilename);
                    cache.IsNewlyCreated = true;
                    cache.SaveCache(reporting);
                end
                
            catch ex
                reporting.ShowWarning('CoreMexCache:FailedtoLoadCacheFile', ['Error when loading cache file ' cacheFilename '. All the mex files will be recompiled.'], ex);
                cache = CoreMexCache(cacheFilename);
            end
        end        
    end
    
    methods
        function obj = CoreMexCache(cacheFilename, mex_info_map)
            if nargin > 0
                obj.CacheFilename = cacheFilename;
                if nargin > 1 && ~isempty(mex_info_map)
                    obj.MexInfoMap = mex_info_map;
                else
                    obj.MexInfoMap = containers.Map;
                end
            end
        end
        
        function SaveCache(obj, reporting)
            cache_filename = obj.GetCacheFilename;
            
            try
                value = [];
                value.cache = obj;
                CoreSaveXml(obj, 'Cache', cache_filename, reporting);
           catch ex
                reporting.ErrorFromException('CoreMexCache:FailedtoSaveCacheFile', ['Unable to save mex cache file ' cache_filename], ex);
            end
        end
        
        function cacheFileName = GetCacheFilename(obj)
            cacheFileName = obj.CacheFilename;
        end
        
        function UpdateCache(obj, processed_mex_file_list, reporting)
            % Update the saved map without removing entries not on our
            % current list
            any_changes = false;
            for mex_file_key = processed_mex_file_list.keys
                mex_file_value = processed_mex_file_list(mex_file_key{1});
                
                % Determine if there are any changes in the current key
                if ~any_changes
                    if ~obj.MexInfoMap.isKey(mex_file_key{1})
                        any_changes = true;
                    else
                        any_changes = any_changes || ~isequal(obj.MexInfoMap(mex_file_key{1}), mex_file_value);
                    end
                end
                obj.MexInfoMap(mex_file_key{1}) = mex_file_value;
                obj.IsNewlyCreated = false;                
            end
            
            % Update the cached file only if there are changes
            if any_changes
                obj.SaveCache(reporting);
            end
        end
    end
end

