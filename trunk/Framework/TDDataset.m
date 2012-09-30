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
        DatasetResults    % Called to fetch results and data for this dataset
        DependencyTracker % Tracks plugin usage to construct dependency lists 
        DiskCache         % Reads and writes to the disk cache for this dataset
        PreviewImages     % Stores the thumbnail preview images
        Reporting         % Object for error and progress reporting
    end
    
    events
        % This event is fired when a plugin has been run for this dataset, and has generated a new preview thumbnail.
        PreviewImageChanged
    end

    methods
        
        % TDDataset is created by the TDPTK class
        function obj = TDDataset(image_info, disk_cache, reporting)
            obj.DiskCache = disk_cache;
            obj.Reporting = reporting;
            obj.DependencyTracker = TDPluginDependencyTracker(disk_cache, reporting);
            obj.PreviewImages = TDPreviewImages(disk_cache, reporting);
            obj.DatasetResults = TDDatasetResults(image_info, obj.PreviewImages, obj.DependencyTracker, @obj.notify, disk_cache, reporting);
        end
        
        % GetResult: Returns the results of a plugin. If a valid result is cached on disk,
        % this wil be returned provided all the dependencies are valid.
        % Otherwise the plugin will be executed and the new result returned.
        % The optional context parameter specifies the region of interest to which the output result will be framed.
        % Specifying a second argument also produces a representative image from
        % the results. For plugins whose result is an image, this will generally be the
        % same as the results.        
        function [result, output_image] = GetResult(obj, plugin_name, context)
            obj.Reporting.ClearStack;
            if nargin < 3
                context = [];
            end
            
            % Reset the dependency stack, since this could be left in a bad state if a previous plugin call caused an exception
            obj.DependencyTracker.ClearStack;
            
            if nargout > 1
                [result, output_image] = obj.DatasetResults.GetResult(plugin_name, context);
            else
                result = obj.DatasetResults.GetResult(plugin_name, context);
            end
            obj.Reporting.ShowAndClear;
            obj.Reporting.ClearStack;
        end
                
        % Save data as a cache file associated with this dataset
        % Used for marker points
        function SaveData(obj, name, data)
            obj.DiskCache.Save(name, data);
            obj.Reporting.ShowAndClear;
        end
        
        % Load data from a cache file associated with this dataset
        function data = LoadData(obj, name)
            data = obj.DiskCache.Load(name);
            obj.Reporting.ShowAndClear;
        end

        % Gets the path of the folder where the results for this dataset are
        % stored
        function dataset_cache_path = GetDatasetCachePath(obj)
            dataset_cache_path = obj.DiskCache.CachePath;
            obj.Reporting.ShowAndClear;
        end

        % Returns a TDImageInfo structure with image information, including the
        % UID, filenames and file path
        function image_info = GetImageInfo(obj)
            image_info = obj.DatasetResults.GetImageInfo;
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
            obj.DiskCache.RemoveAllCachedFiles(remove_framework_files, obj.Reporting);
            obj.PreviewImages.Clear;
            obj.Reporting.ShowAndClear;
        end
        
        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context)
            context_is_enabled = obj.DatasetResults.IsContextEnabled(context);
            obj.Reporting.ShowAndClear;
        end
    end
end