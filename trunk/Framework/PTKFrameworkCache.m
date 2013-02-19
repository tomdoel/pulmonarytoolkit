classdef PTKFrameworkCache < handle
    % PTKFrameworkCache. Part of the internal framework for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the Pulmonary Toolkit.
    %
    %     PTKFrameworkCache stores framework-related information that needs to
    %     persist between sessions, such as the version numbers of the currently
    %     compiled mex files.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        MexInfoMap
        IsNewlyCreated
    end
    
    methods (Static)
        function cache = LoadCache(reporting)
            try
                cache_filename = PTKDirectories.GetFrameworkCacheFilePath;
                if exist(cache_filename, 'file')
                    cache_struct = load(cache_filename);
                    cache = cache_struct.cache;
                    cache.IsNewlyCreated = false;
                else
                    reporting.ShowWarning('PTKFrameworkCache:CacheFileNotFound', 'No cache file found. Will create new one on exit', []);
                    cache = PTKFrameworkCache;
                    cache.IsNewlyCreated = true;
                end
                
            catch ex
                reporting.ErrorFromException('PTKFrameworkCache:FailedtoLoadCacheFile', ['Error when loading cache file ' cache_filename '. Try deleting this file.'], ex);
            end
        end
        
    end
    
    methods
        
        function obj = PTKFrameworkCache
            obj.MexInfoMap = containers.Map;
        end
        
        function SaveCache(obj, reporting)
            cache_filename = PTKDirectories.GetFrameworkCacheFilePath;
            
            try
                cache = obj; %#ok<NASGU>
                save(cache_filename, 'cache');
            catch ex
                reporting.ErrorFromException('PTKFrameworkCache:FailedtoSaveCacheFile', ['Unable to save settings file ' cache_filename], ex);
            end
        end        
    end
end

