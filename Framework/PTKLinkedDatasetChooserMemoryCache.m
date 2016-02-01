classdef PTKLinkedDatasetChooserMemoryCache < handle
    % PTKLinkedDatasetChooserMemoryCache. Part of the internal framework for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the Pulmonary Toolkit.
    %
    %     PTKLinkedDatasetChooserMemoryCache stores a map of PTKLinkedDatasetChooser objects, and
    %     ensures only one PTKLinkedDatasetChooser exists for a given UID. This improves
    %     thread safety by ensuring multiple PTKLinkedDatasetChooser objects aren't
    %     interacting with the same cache files.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        ContextDef
        LinkedDatasetChooserCacheMap
        LinkedRecorderSingleton
        PluginCache
    end
    
    methods
        function obj = PTKLinkedDatasetChooserMemoryCache(context_def, linked_recorder_singleton, plugin_cache)
            obj.ContextDef = context_def;
            obj.LinkedDatasetChooserCacheMap = containers.Map;
            obj.LinkedRecorderSingleton = linked_recorder_singleton;
            obj.PluginCache = plugin_cache;
        end
        
        function linked_dataset_chooser = GetLinkedDatasetChooser(obj, image_info, dataset_disk_cache, reporting)
            uid = image_info.ImageUid;
            if obj.LinkedDatasetChooserCacheMap.isKey(uid)
                linked_dataset_chooser = obj.LinkedDatasetChooserCacheMap(uid);
            else
                linked_dataset_chooser = PTKLinkedDatasetChooser(obj.ContextDef, image_info, dataset_disk_cache, obj.LinkedRecorderSingleton, obj.PluginCache, reporting);
                obj.LinkedDatasetChooserCacheMap(uid) = linked_dataset_chooser;
            end
        end
    end
end

