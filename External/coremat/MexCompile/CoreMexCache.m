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
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
                cacheFilename = PTKDirectories.GetFrameworkCacheFilePath;
                if exist(cacheFilename, 'file')                    
                    cache = CoreLoadXml(cacheFilename, reporting);
                    cache = cache.MexCache;
                    cache.CacheFilename = cacheFilename;
                else
                    reporting.ShowWarning('CoreMexCache:MexCacheFileNotFound', 'No mex cache file found. Will create new one on exit', []);
                    cache = CoreMexCache(cacheFilename);
                    cache.Save(reporting);
                end
                
            catch ex
                reporting.ShowWarning('CoreMexCache:FailedtoLoadCacheFile', ['Error when loading cache file ' cacheFilename '. All the mex files will be recompiled.'], ex);
                cache = CoreMexCache(cacheFilename);
            end
        end        
    end
    
    methods
        function obj = CoreMexCache(cacheFilename)
            obj.MexInfoMap = containers.Map;
            if nargin > 0
                obj.CacheFilename = cacheFilename;
            end
        end
        
        function SaveCache(obj, reporting)
            cache_filename = obj.GetCacheFilename;
            
            try
                value = [];
                value.cache = obj;
                CoreSaveXml(obj, 'Cache', cache_filename, reporting);
                PTKDiskUtilities.Save(cache_filename, value);
           catch ex
                reporting.ErrorFromException('PTKFrameworkCache:FailedtoSaveCacheFile', ['Unable to save mex cache file ' cache_filename], ex);
            end
        end
        
        function cacheFileName = GetCacheFilename(~)
            cacheFileName = PTKDirectories.GetFrameworkCacheFilePath;
        end
        
        function UpdateCache(obj, processed_mex_file_list, reporting)
            obj.MexInfoMap = processed_mex_file_list;
            obj.IsNewlyCreated = false;
            obj.SaveCache(reporting);
        end
    end
end

