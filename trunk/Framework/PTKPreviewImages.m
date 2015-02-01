classdef PTKPreviewImages < PTKBaseClass
    % PTKPreviewImages. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     PTKPreviewImages caches a list of 'preview images' which are thumbnails 
    %     of previous plugin results for this dataset. These images are used by
    %     the GUI as a 'preview' of the results obtained when running a
    %     plugin.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        DatasetDiskCache       % disk cache for this dataset
        Previews        % preview thumnail images
    end
    
    methods
        function obj = PTKPreviewImages(dataset_disk_cache, reporting)
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.LoadPreviewFile(reporting);
        end

        % Add a new thumbnail preview
        function AddPreview(obj, plugin_name, preview_image, reporting)
            if ~obj.Previews.isKey(plugin_name) || (preview_image ~= obj.Previews(plugin_name));
                obj.Previews(plugin_name) = preview_image;
                obj.SavePreviewFile(reporting);
            end
        end
        
        % Check if a preview thumbnail has previously been created
        function preview_exists = DoesPreviewExist(obj, plugin_name)
            preview_exists = obj.Previews.isKey(plugin_name);
        end
        
        % Fetch a cached preview image
        function preview_image = GetPreview(obj, plugin_name, reporting)
            if obj.Previews.isKey(plugin_name)
                preview_image = obj.Previews(plugin_name);
            else
                preview_image = [];
            end
        end
        
        % Erase previews. Typically you would do this when erasing the disk
        % cache, so that previews do not become stale
        function Clear(obj, reporting)
            obj.Previews = containers.Map;
            obj.SavePreviewFile(reporting);
        end
        
    end
    
    methods (Access = private)
        
        % Cache previews on disk
        function LoadPreviewFile(obj, reporting)
            cached_previews = obj.DatasetDiskCache.LoadData(PTKSoftwareInfo.PreviewImageFileName, reporting);
            if isempty(cached_previews)
                obj.Previews = containers.Map;
            else
                obj.Previews = cached_previews;
            end
        end
        
        % Load cached previews from disk
        function SavePreviewFile(obj, reporting)
            obj.DatasetDiskCache.SaveData(PTKSoftwareInfo.PreviewImageFileName, obj.Previews, reporting);
        end
    end
    
end
