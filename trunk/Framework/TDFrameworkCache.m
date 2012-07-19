classdef TDFrameworkCache < handle
    % TDFrameworkCache. Part of the internal framework for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the Pulmonary Toolkit.
    %
    %     TDFrameworkCache stores framework-related information that needs to
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
        function settings_dir = GetCacheDirectory
            settings_dir = TDSoftwareInfo.GetApplicationDirectoryAndCreateIfNecessary;
        end
        
        function settings_file_path = GetCacheFilePath
            settings_dir = TDFrameworkCache.GetCacheDirectory;
            cache_filename = TDSoftwareInfo.FrameworkCacheFileName;
            settings_file_path = fullfile(settings_dir, cache_filename);
        end
        
        function cache = LoadCache(reporting)
            try
                cache_filename = TDFrameworkCache.GetCacheFilePath;
                if exist(cache_filename, 'file')
                    cache_struct = load(cache_filename);
                    cache = cache_struct.cache;
                    cache.IsNewlyCreated = false;
                else
                    reporting.ShowWarning('TDFrameworkCache:CacheFileNotFound', 'No cache file found. Will create new one on exit', []);
                    cache = TDFrameworkCache;
                    cache.IsNewlyCreated = true;
                end
                
            catch ex
                reporting.ErrorFromException('TDFrameworkCache:FailedtoLoadCacheFile', ['Error when loading cache file ' cache_filename '. Try deleting this file.'], ex);
            end
        end
        
    end
    
    methods
        
        function obj = TDFrameworkCache
            obj.MexInfoMap = containers.Map;
        end
        
        function SaveCache(obj, reporting)
            cache_path = TDFrameworkCache.GetCacheDirectory;
            cache_filename = TDFrameworkCache.GetCacheFilePath;
            if ~exist(cache_path, 'dir')
                reporting.ShowMessage('TDFrameworkCache:NewSettingsDirectory', ['Creating settings directory: ' cache_path]);
                mkdir(cache_path);
            end
            
            try
                cache = obj; %#ok<NASGU>
                save(cache_filename, 'cache');
            catch ex
                reporting.ErrorFromException('TDFrameworkCache:FailedtoSaveCacheFile', ['Unable to save settings file ' cache_filename], ex);
            end
        end        
    end
end

