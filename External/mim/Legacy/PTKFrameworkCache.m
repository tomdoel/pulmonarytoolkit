classdef PTKFrameworkCache < handle
    % PTKFrameworkCache. Legacy support class. Replaced by CoreMexCache.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        MexInfoMap
        IsNewlyCreated
    end
    
    methods (Static)
        function cache = LoadLegacyCache(legacy_cache_filename, new_cache_filename, reporting)
            try
                if exist(legacy_cache_filename, 'file')
                    cache_struct = MimDiskUtilities.Load(legacy_cache_filename);
                    cache = cache_struct.cache;
                    cache = CoreMexCache(new_cache_filename, cache.MexInfoMap);
                    cache.IsNewlyCreated = false;
                    cache.CacheFilename = new_cache_filename;
                else
                    cache = [];
                    reporting.ShowWarning('PTKFrameworkCache:CacheFileNotFound', 'No cache file found. Will create new one on exit', []);
                end
                
            catch ex
                cache = [];                
                reporting.ShowWarning('PTKFrameworkCache:FailedtoLoadCacheFile', ['Error when loading legacy cache file ' legacy_cache_filename '. Try deleting this file.'], ex);
            end
        end
        
    end
    
    methods
        function obj = PTKFrameworkCache
            obj.MexInfoMap = containers.Map;
        end
    end
end

