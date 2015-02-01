classdef PTKDatasetMemoryCache < handle
    % PTKDatasetMemoryCache. Part of the internal framework for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the Pulmonary Toolkit.
    %
    %     PTKDatasetMemoryCache stores a map of PTKDataset objects, and
    %     ensures only one PTKDataset exists for a given UID. This improves
    %     thread safety by ensuring multiple PTKDataset objects aren't
    %     interacting with the same cache files.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        DatasetDiskCacheMap
    end
    
    methods
        function obj = PTKDatasetMemoryCache
            obj.DatasetDiskCacheMap = containers.Map;
        end
        
        function dataset_disk_cache = GetDatasetDiskCache(obj, uid, reporting)
            if obj.DatasetDiskCacheMap.isKey(uid)
                dataset_disk_cache = obj.DatasetDiskCacheMap(uid);
            else
                dataset_disk_cache = PTKDatasetDiskCache(uid, reporting);
                obj.DatasetDiskCacheMap(uid) = dataset_disk_cache;
            end
        end
    end
end

