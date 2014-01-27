classdef PTKDataset < handle
    % PTKDataset. Use this class to obtain results and associated data for a particualar dataset.
    %
    %     This class is used by scripts and GUI applications to run
    %     calculations, fetch cached results and access data associated with a
    %     dataset. The difference between PTKDataset and PTKDatasetResults is that
    %     PTKDataset is called from outside the toolkit, whereas PTKDatasetResults
    %     is called by plugins during their RunPlugin() call. PTKDataset 
    %     calls PTKDatasetResults, but provides additional progress and error 
    %     reporting and dependency tracking.
    %
    %     Each dataset will have its own instance of PTKDataset.
    %
    %     You should not create this class directly. Instead, create an instance of
    %     the class PTKMain and use the methods CreateDatasetFromInfo and
    %     CreateDatasetFromUid to get a PTKDataset object for each dataset you are
    %     working with.
    %
    %     Example: Replace <image path> and <filenames> with the path and filenames
    %     to your image data.
    %
    %         image_info = PTKImageInfo( <image path>, <filenames>, [], [], [], []);
    %         ptk = PTKMain;
    %         dataset = ptk.CreateDatasetFromInfo(image_info);
    %
    %     You can then obtain results from this dataset, e.g.
    %
    %         airways = dataset.GetResult('PTKAirways');
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        
        % Multiple datasets can be linked together. The LinkedDatasetChooser is
        % used to send API calls to the correct dataset.
        LinkedDatasetChooser
        
        % Manages the heirarchy (call stack) of plugins calling other plugins.
        % This is used for dependency checking and to prevent recursion. 
        % Each PTKDataset API has its own call stack which relates to the calls
        % being made at that interface. Note that when datasets are linked, one
        % dataset may end up calling another to fetch results; however, the same
        % call stack must be used for the dependency checking to work correctly.
        % This means that when a GetResult() call is
        % made on a dataset, the call stack depends not on which dataset is
        % being called, but where the call originated from. For this reason, the
        % call stacks are owned by the PTKDataset class (where calls originate)
        % and passed through.
        DatasetStack
        
        % Object for error and progress reporting. PTKDataset uses this to clean
        % up reporting in the case of error conditions.
        Reporting         
    end
    
    events
        % This event is fired when a plugin has been run for this dataset, and
        % has generated a new preview thumbnail.
        PreviewImageChanged
    end

    methods
        
        % PTKDataset is created by the PTKMain class
        function obj = PTKDataset(image_info, dataset_disk_cache, reporting)
            obj.DatasetStack = PTKDatasetStack(reporting);
            obj.Reporting = reporting;
            obj.LinkedDatasetChooser = PTKLinkedDatasetChooser(image_info, @obj.notify, dataset_disk_cache, reporting);
        end
        
        function LinkDataset(obj, linked_name, dataset_to_link)
            % Associates another dataset to this (e.g. multiple datasets for the
            % same patient)
            linked_dataset_chooser = dataset_to_link.LinkedDatasetChooser;
            obj.LinkedDatasetChooser.AddLinkedDataset(linked_name, linked_dataset_chooser);
        end

        function [result, output_image] = GetResult(obj, plugin_name, varargin)
            % GetResult: Returns the results of a plugin.
            % If a valid result is cached on disk,
            % this wil be returned provided all the dependencies are valid.
            % Otherwise the plugin will be executed and the new result returned.
            % The optional context parameter specifies the region of interest to which the output result will be framed.
            % Specifying a second argument also produces a representative image from
            % the results. For plugins whose result is an image, this will generally be the
            % same as the results.
            if nargout > 1
                [result, ~, output_image] = obj.GetResultWithCacheInfo(plugin_name, varargin{:});
            else
                [result, ~] = obj.GetResultWithCacheInfo(plugin_name, varargin{:});
            end
        end
                
        function [result, cache_info, output_image] = GetResultWithCacheInfo(obj, plugin_name, context, varargin)
            if nargin < 3
                context = [];
            end
            
            obj.PreCallTidy;
            
            % Reset the dependency stack, since this could be left in a bad state if a previous plugin call caused an exception
            obj.DatasetStack.ClearStack;
            
            try
                if nargout > 2
                    [result, cache_info, output_image] = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetResult(plugin_name, obj.DatasetStack, context);
                else
                    [result, cache_info] = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetResult(plugin_name, obj.DatasetStack, context, varargin{2:end});
                end
            catch ex
                
                % Tidy up
                obj.DatasetStack.ClearStack;
                obj.PostCallTidy;
                
                rethrow(ex)
            end
            
            % Tidy up
            obj.DatasetStack.ClearStack;
            obj.PostCallTidy;
        end
        
        function SaveEditedResult(obj, plugin_name, edited_result, context, varargin)
            if nargin < 4
                context = [];
            end
            
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(varargin{:}).SaveEditedPluginResult(plugin_name, context, edited_result, obj.DatasetStack);
            obj.PostCallTidy;
        end
        
        function SaveData(obj, name, data, varargin)
            % Save data as a cache file associated with this dataset
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(varargin{:}).SaveData(name, data);
            obj.PostCallTidy;
        end
        
        function data = LoadData(obj, name, varargin)
            % Load data from a cache file associated with this dataset
            obj.PreCallTidy;
            data = obj.LinkedDatasetChooser.GetDataset(varargin{:}).LoadData(name);
            obj.PostCallTidy;
        end

        function dataset_cache_path = GetDatasetCachePath(obj, varargin)
            % Gets the path of the folder where the results for this dataset are stored
            obj.PreCallTidy;
            dataset_cache_path = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetDatasetCachePath;
            obj.PostCallTidy;
        end
        
        function dataset_cache_path = GetEditedResultsPath(obj, varargin)
            % Gets the path of the folder where the edited results for this dataset are stored
            obj.PreCallTidy;
            dataset_cache_path = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetEditedResultsPath;
            obj.PostCallTidy;
        end
        
        function dataset_cache_path = GetOutputPath(obj, varargin)
            % Gets the path of the folder where the output for this dataset are stored
            obj.PreCallTidy;
            dataset_cache_path = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetOutputPath;
            obj.PostCallTidy;
        end

        function dataset_cache_path = GetOutputPathAndCreateIfNecessary(obj, varargin)
            % Gets the path of the folder where the output files for this dataset are stored
            obj.PreCallTidy;
            dataset_cache_path = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetOutputPathAndCreateIfNecessary;
            obj.PostCallTidy;
        end
        
        function image_info = GetImageInfo(obj, varargin)
            % Returns a PTKImageInfo structure with image information, including the
            % UID, filenames and file path
            obj.PreCallTidy;
            image_info = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetImageInfo;
            obj.PostCallTidy;
        end

        function template_image = GetTemplateImage(obj, context, varargin)
            % Returns an empty template image for the specified context
            % See PTKImageTemplates.m for valid contexts
            
            obj.PreCallTidy;
            template_image = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetTemplateImage(context, obj.DatasetStack);
            obj.PostCallTidy;
        end
        
        function preview = GetPluginPreview(obj, plugin_name, varargin)
            % Gets a thumbnail image of the last result for this plugin

            % Note: we don't do any pre/post call tidying on this method, as we
            % permit it to be called while another call is in progress (which
            % may happen during a PreviewImageChanged notification).
            
            preview = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetPluginPreview(plugin_name);
        end

        function ClearCacheForThisDataset(obj, remove_framework_files, varargin)
            % Removes all the cache files associated with this dataset. 
            % Cache files store the results of plugins so they need only be computed once for
            % each dataset. Clearing the cache files forces recomputation of all
            % results.
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(varargin{:}).ClearCacheForThisDataset(remove_framework_files);
            obj.PostCallTidy;
        end
        
        function DeleteCacheForThisDataset(obj, varargin)
            % Removes the cache file fodler associated with this dataset. This
            % should not be called unless you are completely removing the dataset
            
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(varargin{:}).DeleteCacheForThisDataset;
            obj.PostCallTidy;
        end
        
        function context_is_enabled = IsContextEnabled(obj, context, varargin)
            % Check to see if a context has been disabled for this dataset, due to a
            % failure when running the plugin that generates the template image for
            % that context.
        
            obj.PreCallTidy;
            context_is_enabled = obj.LinkedDatasetChooser.GetDataset(varargin{:}).IsContextEnabled(context);
            obj.PostCallTidy;
        end
        
        function is_gas_mri = IsGasMRI(obj, varargin)
            % Check if this is a hyperpolarised gas MRI image
        
            obj.PreCallTidy;
            is_gas_mri = obj.LinkedDatasetChooser.GetDataset(varargin{:}).IsGasMRI(obj.DatasetStack);
            obj.PostCallTidy;
        end 
    end
    
    methods (Access = private)
        
        function PreCallTidy(obj)
            % Called before methods are executed in order to ensure the Framework is
            % in a tidy state after any previous error conditions
            
            obj.Reporting.ClearProgressStack;
        end
        
        function PostCallTidy(obj)
            % Called after methods are executed in order to ensure the Framework is
            % in a tidy state after any previous error conditions
            
            obj.Reporting.ShowAndClearPendingMessages;
            obj.Reporting.ClearProgressStack;
        end
    end
end