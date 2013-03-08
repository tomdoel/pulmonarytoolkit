classdef PTKLinkedDatasetChooser < handle
    % PTKLinkedDatasetChooser. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     PTKLinkedDatasetChooser is used to select between linked datasets.
    %     By default, each dataset acts independently, but you can link datasets
    %     together (for example, if you wanted to register images between two
    %     datasets). When datasets are linked, one is the primary dataset, and
    %     linked results are stored in the primary cache. Plugins can choose
    %     which of the linked datasets from which they access results.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties (Access = private)
        PrimaryDatasetResults % Handle to the PTKDatasetResults object for this dataset
        LinkedDatasetChooserList % Handles to PTKLinkedDatasetChooser objects for all linked datasets, including this one
        PrimaryDatasetUid     % The uid of this dataset
        Reporting
    end
    
    methods
        function obj = PTKLinkedDatasetChooser(image_info, external_notify_function, dataset_disk_cache, reporting)
            primary_dataset_results = PTKDatasetResults(image_info, obj, external_notify_function, dataset_disk_cache, reporting);
            obj.PrimaryDatasetUid = primary_dataset_results.GetImageInfo.ImageUid;
            obj.PrimaryDatasetResults = primary_dataset_results;
            obj.LinkedDatasetChooserList = containers.Map;
            obj.LinkedDatasetChooserList(obj.PrimaryDatasetUid) = obj;
            obj.Reporting = reporting;
        end

        function AddLinkedDataset(obj, linked_name, linked_dataset_chooser)
            linked_uid = linked_dataset_chooser.PrimaryDatasetUid;
            obj.LinkedDatasetChooserList(linked_uid) = linked_dataset_chooser;
            obj.LinkedDatasetChooserList(linked_name) = linked_dataset_chooser;
        end
        
        function dataset_results = GetDataset(obj, dataset_name)
            dataset_results = obj.FindLinkedDatasetChooser(dataset_name).PrimaryDatasetResults;
            
        end

        % RunPlugin: Returns the results of a plugin. If a valid result is cached on disk,
        % this wil be returned provided all the dependencies are valid.
        % Otherwise the plugin will be executed and the new result returned.
        % The optional context parameter specifies the region of interest to which the output result will be framed.
        % Specifying a second argument also produces a representative image from
        % the results. For plugins whose result is an image, this will generally be the
        % same as the results.
        function [result, cache_info, output_image] = GetResult(obj, plugin_name, dataset_call_stack, context, varargin)
            if nargin < 4
                context = [];
            end
            
            if nargout > 2
                [result, cache_info, output_image] = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.GetResult(plugin_name, dataset_call_stack, context);
            else
                [result, cache_info] = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.GetResult(plugin_name, dataset_call_stack, context);
            end
        end

        % Save data as a cache file associated with the dataset
        function SaveData(obj, name, data, varargin)
            obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.SaveData(name, data);
        end

        % Load data from a cache file associated with the dataset
        function data = LoadData(obj, name, varargin)
            data = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.LoadData(name, obj.Reporting);
        end

        % Gets the path of the folder where the results for this dataset are
        % stored
        function dataset_cache_path = GetDatasetCachePath(obj, varargin)
            dataset_cache_path = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.GetCachePath;
        end

        % Gets the path of the folder where the output files for this dataset are
        % stored
        function dataset_cache_path = GetOutputPathAndCreateIfNecessary(obj, varargin)
            dataset_cache_path = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.GetOutputPathAndCreateIfNecessary;
        end

        % Returns a PTKImageInfo structure with image information, including the
        % UID, filenames and file path
        function image_info = GetImageInfo(obj, varargin)
            image_info = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.GetImageInfo;
        end

        % Returns an empty template image for the specified context
        % See PTKImageTemplates.m for valid contexts
        function template_image = GetTemplateImage(obj, context, dataset_stack, varargin)
            template_image = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.GetTemplateImage(context, dataset_stack);
        end

        % Gets a thumbnail image of the last result for this plugin
        function preview = GetPluginPreview(obj, plugin_name, varargin)
            preview = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.GetPluginPreview(plugin_name);
        end

        % Removes all the cache files associated with this dataset. Cache files
        % store the results of plugins so they need only be computed once for
        % each dataset. Clearing the cache files forces recomputation of all
        % results.
        function ClearCacheForThisDataset(obj, remove_framework_files, varargin)
            obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.ClearCacheForThisDataset(remove_framework_files);
        end
        
        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context, varargin)
            context_is_enabled = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.IsContextEnabled(context);
        end
        
        function is_gas_mri = IsGasMRI(obj, dataset_stack, varargin)
            is_gas_mri = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.IsGasMRI(dataset_stack);
        end
        
        function valid = CheckDependencyValid(obj, dependency, varargin)
            valid = obj.FindLinkedDatasetChooser(varargin{:}).PrimaryDatasetResults.CheckDependencyValid(dependency);
        end        
    end

    methods (Access = private)
        function linked_dataset_chooser = FindLinkedDatasetChooser(obj, dataset_name)
            if nargin < 2
                dataset_name = [];
            end
            if isempty(dataset_name)
                dataset_name = obj.PrimaryDatasetUid;
            end
            if ~obj.LinkedDatasetChooserList.isKey(dataset_name)
                obj.Reporting.Error('PTKLinkedDatasetChooser:DatasetNotFound', 'No linked dataset was found with this name. Did you add the dataset with LinkDataset()?'); 
            end
            linked_dataset_chooser = obj.LinkedDatasetChooserList(dataset_name);
        end
    end
end
