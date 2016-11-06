classdef MimCachePolicy
    % MimCachePolicy. Describes the type of caching allowed for a plugin result
    %
    %   Plugins can define caching policy for the disk and memory caches.
    %   Not all values are supported by each cache type.
    %
    %    Off       - Never cache results. This means the plugin will be run
    %                every time. 
    %
    %                For the memory cache, use this value if 
    %                a) the execution time is very fast, or:
    %                b) the plugin result is very large and you do not want
    %                   it to consume memory, or:
    %                c) the plugin result is only requested once by a
    %                   single plugin and you will no be requesting the
    %                   result directly
    %
    %                For the disk cache, only use this value if:
    %                a) the execution time is very fast, or:
    %                b) the plugin result is only requested once by a
    %                   single plugin and you will no be requesting the
    %                   result directly
    %
    %    Temporary - Only valid for memory cache. This means the result
    %                will be cached in memory until the end of the original
    %                API call GetResult(). This value is useful if a plugin
    %                result will be requested multiple times by one or more
    %                plugins during a single API call, but the result is
    %                not likely to be required outside of this.
    %
    %    Session   - The result will be deleted when the MimDataset object
    %                is destroyed, typically when you move onto a different
    %                dataset. This is useful when you want the speed
    %                advantages of a cache only while you are working on a
    %                dataset
    %
    %    Permanent - Only valid for a disk cache. The cache result will
    %                remain in the dataset until the cache is cleared
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    enumeration
        Off       % Never cache results
        Temporary % Cached reslts until end of current API call
        Session   % Cache results only until the MimDataset object is destroyed
        Permanent % Cache results permanently
    end
end

