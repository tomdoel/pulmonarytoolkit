classdef MimLinkedDatasetChooserMemoryCache < handle
    % MimLinkedDatasetChooserMemoryCache. Part of the internal framework for the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the TD MIM Toolkit.
    %
    %     MimLinkedDatasetChooserMemoryCache stores a map of MimLinkedDatasetChooser objects, and
    %     ensures only one MimLinkedDatasetChooser exists for a given UID. This improves
    %     thread safety by ensuring multiple MimLinkedDatasetChooser objects aren't
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
        ContextDef
        FrameworkAppDef
        LinkedDatasetChooserCacheMap
        LinkedRecorderSingleton
        PluginCache
    end
    
    methods
        function obj = MimLinkedDatasetChooserMemoryCache(framework_app_def, linked_recorder_singleton, plugin_cache)
            obj.ContextDef = framework_app_def.GetContextDef;
            obj.FrameworkAppDef = framework_app_def;
            obj.LinkedDatasetChooserCacheMap = containers.Map;
            obj.LinkedRecorderSingleton = linked_recorder_singleton;
            obj.PluginCache = plugin_cache;
        end
        
        function linked_dataset_chooser = GetLinkedDatasetChooser(obj, image_info, dataset_disk_cache, reporting)
            uid = image_info.ImageUid;
            if obj.LinkedDatasetChooserCacheMap.isKey(uid)
                linked_dataset_chooser = obj.LinkedDatasetChooserCacheMap(uid);
            else
                linked_dataset_chooser = MimLinkedDatasetChooser(obj.FrameworkAppDef, obj.ContextDef, image_info, dataset_disk_cache, obj.LinkedRecorderSingleton, obj.PluginCache, reporting);
                obj.LinkedDatasetChooserCacheMap(uid) = linked_dataset_chooser;
            end
        end
        
        function DeleteSeries(obj, series_uids, reporting)
            for series_uid_cell = series_uids
                series_uid = series_uid_cell{1};
                if obj.LinkedDatasetChooserCacheMap.isKey(series_uid)
                    obj.LinkedDatasetChooserCacheMap.remove(series_uid);
                end
            end
        end        
    end
end

