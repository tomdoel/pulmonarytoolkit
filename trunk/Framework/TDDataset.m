classdef TDDataset < handle
    % TDDataset. Use this class to obtain results and associated data for a particualar dataset.
    %
    %     This class is used by scripts and GUI applications to run
    %     calculations, fetch cached results and access data associated with a
    %     dataset. The difference between TDDataset and TDDatasetResults is that
    %     TDDataset is called from outside the toolkit, whereas TDDatasetResults
    %     is called by plugins during their RunPlugin() call. TDDataset 
    %     calls TDDatasetResults, but provides additional progress and error 
    %     reporting and dependency tracking.
    %
    %     Each dataset will have its own instance of TDDataset.
    %
    %     You should not create this class directly. Instead, create an instance of
    %     the class TDPTK and use the methods CreateDatasetFromInfo and
    %     CreateDatasetFromUid to get a TDDataset object for each dataset you are
    %     working with.
    %
    %     Example: Replace <image path> and <filenames> with the path and filenames
    %     to your image data.
    %
    %         image_info = TDImageInfo( <image path>, <filenames>, [], [], [], []);
    %         ptk = TDPTK;
    %         dataset = ptk.CreateDatasetFromInfo(image_info);
    %
    %     You can then obtain results from this dataset, e.g.
    %
    %         airways = dataset.GetResult('TDAirways');
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        DatasetDiskCache  % Reads and writes to the disk cache for this dataset
        LinkedDatasetChooser % Chooses between all the datasets linked to this one
        PreviewImages     % Stores the thumbnail preview images
        PluginCallStack   % Manages the heirarchy of plugins calling other plugins
        Reporting         % Object for error and progress reporting
    end
    
    events
        % This event is fired when a plugin has been run for this dataset, and has generated a new preview thumbnail.
        PreviewImageChanged
    end

    methods
        
        % TDDataset is created by the TDPTK class
        function obj = TDDataset(image_info, dataset_disk_cache, reporting)
            obj.PluginCallStack = TDPluginCallStack(reporting);
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.Reporting = reporting;
            obj.PreviewImages = TDPreviewImages(dataset_disk_cache, reporting);
            dataset_results = TDDatasetResults(image_info, obj.PreviewImages, @obj.notify, dataset_disk_cache, reporting);
            obj.LinkedDatasetChooser = TDLinkedDatasetChooser(dataset_results);
        end
        
        % Link another dataset to this
        function LinkDataset(obj, linked_name, dataset_to_link)
            linked_dataset_chooser = dataset_to_link.LinkedDatasetChooser;
            obj.LinkedDatasetChooser.AddLinkedDataset(linked_name, linked_dataset_chooser);
        end

        % GetResult: Returns the results of a plugin. If a valid result is cached on disk,
        % this wil be returned provided all the dependencies are valid.
        % Otherwise the plugin will be executed and the new result returned.
        % The optional context parameter specifies the region of interest to which the output result will be framed.
        % Specifying a second argument also produces a representative image from
        % the results. For plugins whose result is an image, this will generally be the
        % same as the results.        
        function [result, output_image] = GetResult(obj, plugin_name, context, dataset_uid)
            obj.Reporting.ClearStack;
            if nargin < 3
                context = [];
            end
            if nargin < 4
                dataset_uid = [];
            end
            
            % Reset the dependency stack, since this could be left in a bad state if a previous plugin call caused an exception
            obj.PluginCallStack.ClearStack;
            
            if nargout > 1
                [result, output_image] = obj.LinkedDatasetChooser.GetResult(plugin_name, obj.PluginCallStack, context, dataset_uid);
            else
                result = obj.LinkedDatasetChooser.GetResult(plugin_name, obj.PluginCallStack, context, dataset_uid);
            end
            obj.Reporting.ShowAndClear;
            obj.Reporting.ClearStack;
        end
                
        % Save data as a cache file associated with this dataset
        % Used for marker points
        function SaveData(obj, name, data)
            obj.DatasetDiskCache.SaveData(name, data, obj.Reporting);
            obj.Reporting.ShowAndClear;
        end
        
        % Load data from a cache file associated with this dataset
        function data = LoadData(obj, name)
            data = obj.DatasetDiskCache.LoadData(name, obj.Reporting);
            obj.Reporting.ShowAndClear;
        end

        % Gets the path of the folder where the results for this dataset are
        % stored
        function dataset_cache_path = GetDatasetCachePath(obj)
            dataset_cache_path = obj.DatasetDiskCache.GetCachePath(obj.Reporting);
            obj.Reporting.ShowAndClear;
        end

        % Returns a TDImageInfo structure with image information, including the
        % UID, filenames and file path
        function image_info = GetImageInfo(obj, dataset_uid)
            if nargin < 2
                dataset_uid = [];
            end
            image_info = obj.LinkedDatasetChooser.GetImageInfo(dataset_uid);
            obj.Reporting.ShowAndClear;
        end

        % Gets a thumbnail image of the last result for this plugin
        function preview = GetPluginPreview(obj, plugin_name)
            preview = obj.PreviewImages.GetPreview(plugin_name);
            obj.Reporting.ShowAndClear;
        end

        % Removes all the cache files associated with this dataset. Cache files
        % store the results of plugins so they need only be computed once for
        % each dataset. Clearing the cache files forces recomputation of all
        % results.
        function ClearCacheForThisDataset(obj, remove_framework_files)
            obj.DatasetDiskCache.RemoveAllCachedFiles(remove_framework_files, obj.Reporting);
            obj.PreviewImages.Clear;
            obj.Reporting.ShowAndClear;
        end
        
        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context, dataset_uid)
            if nargin < 3
                dataset_uid = [];
            end
            context_is_enabled = obj.LinkedDatasetChooser.IsContextEnabled(context, dataset_uid);
            obj.Reporting.ShowAndClear;
        end
    end
end