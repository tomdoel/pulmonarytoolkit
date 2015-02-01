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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        LinkedDatasetChooserCacheMap
        LinkedRecorderSingleton
    end
    
    methods
        function obj = PTKLinkedDatasetChooserMemoryCache(linked_recorder_singleton)
            obj.LinkedDatasetChooserCacheMap = containers.Map;
            obj.LinkedRecorderSingleton = linked_recorder_singleton;
        end
        
        function linked_dataset_chooser = GetLinkedDatasetChooser(obj, image_info, dataset_disk_cache, reporting)
            uid = image_info.ImageUid;
            if obj.LinkedDatasetChooserCacheMap.isKey(uid)
                linked_dataset_chooser = obj.LinkedDatasetChooserCacheMap(uid);
            else
                linked_dataset_chooser = PTKLinkedDatasetChooser(image_info, dataset_disk_cache, obj.LinkedRecorderSingleton, reporting);
                obj.LinkedDatasetChooserCacheMap(uid) = linked_dataset_chooser;
            end
        end
    end
end

