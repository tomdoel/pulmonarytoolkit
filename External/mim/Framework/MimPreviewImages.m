classdef MimPreviewImages < CoreBaseClass
    % Caches a list of 'preview images' which are thumbnails 
    % of previous plugin results for this dataset. These images are used by
    % the GUI as a 'preview' of the results obtained when running a plugin.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        Config                 % configuration which stroes the preview image cache filename
        DatasetDiskCache       % disk cache for this dataset
        Previews               % preview thumnail images
    end
    
    methods
        function obj = MimPreviewImages(framework_app_def, dataset_disk_cache, reporting)
            obj.Config = framework_app_def.GetFrameworkConfig();
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.LoadPreviewFile(reporting);
        end

        function AddPreview(obj, plugin_name, preview_image, reporting)
            % Add a new thumbnail preview
            if ~obj.Previews.isKey(plugin_name) || (preview_image ~= obj.Previews(plugin_name));
                obj.Previews(plugin_name) = preview_image;
                obj.SavePreviewFile(reporting);
            end
        end
        
        function preview_exists = DoesPreviewExist(obj, plugin_name)
            % Check if a preview thumbnail has previously been created
            preview_exists = obj.Previews.isKey(plugin_name);
        end
        
        function preview_image = GetPreview(obj, plugin_name, reporting)
            % Fetch a cached preview image
            if obj.Previews.isKey(plugin_name)
                preview_image = obj.Previews(plugin_name);
            else
                preview_image = [];
            end
        end
        
        function Clear(obj, reporting)
            % Erase previews. Typically you would do this when erasing the disk
            % cache, so that previews do not become stale
            obj.Previews = containers.Map();
            obj.SavePreviewFile(reporting);
        end
    end
    
    methods (Access = private)    
        function LoadPreviewFile(obj, reporting)
            % Cache previews on disk
            cached_previews = obj.DatasetDiskCache.LoadData(obj.Config.PreviewImageFileName, reporting);
            if isempty(cached_previews)
                obj.Previews = containers.Map();
            else
                obj.Previews = cached_previews;
            end
        end
        
        function SavePreviewFile(obj, reporting)
            % Load cached previews from disk
            obj.DatasetDiskCache.SaveData(obj.Config.PreviewImageFileName, obj.Previews, reporting);
        end
    end
end
