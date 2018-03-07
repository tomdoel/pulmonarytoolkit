classdef MimDatasetApiCache < handle
    % MimDatasetApiCache. Part of the internal framework for the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the TD MIM Toolkit.
    %
    %     MimDatasetApiCache stores a map of MimDataset objects, and
    %     ensures only one MimDataset exists for a given UID. This improves
    %     thread safety by ensuring multiple MimDataset objects aren't
    %     interacting with the same cache files.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        FrameworkAppDef
        DatasetCacheMap
    end
    
    methods
        function obj = MimDatasetApiCache(framework_app_def)
            obj.FrameworkAppDef = framework_app_def;
            obj.DatasetCacheMap = containers.Map;
        end
        
        function dataset_disk_cache = GetDatasetDiskCache(obj, uid, reporting)
            if obj.DatasetCacheMap.isKey(uid)
                dataset_disk_cache = obj.DatasetCacheMap(uid);
            else
                dataset_disk_cache = MimDatasetCacheSelector(uid, obj.FrameworkAppDef, reporting);
                obj.DatasetCacheMap(uid) = dataset_disk_cache;
            end
        end
        
        function DeleteSeries(obj, series_uids, reporting)
            for series_uid_cell = series_uids
                series_uid = series_uid_cell{1};
                if obj.DatasetCacheMap.isKey(series_uid)
                    obj.DatasetCacheMap.remove(series_uid);
                end
            end
        end
    end
end

