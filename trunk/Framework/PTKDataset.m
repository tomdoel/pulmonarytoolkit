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
        function [result, output_image] = GetResult(obj, plugin_name, varargin)
            if nargout > 1
                [result, ~, output_image] = obj.GetResultWithCacheInfo(plugin_name, varargin{:});
            else
                [result, ~] = obj.GetResultWithCacheInfo(plugin_name, varargin{:});
            end
        end
                
        function [result, cache_info, output_image] = GetResultWithCacheInfo(obj, plugin_name, varargin)
            obj.PreCallTidy;
            
            % Reset the dependency stack, since this could be left in a bad state if a previous plugin call caused an exception
            obj.DatasetStack.ClearStack;
            
            try
                if nargout > 2
                    [result, cache_info, output_image] = obj.LinkedDatasetChooser.GetResult(plugin_name, obj.DatasetStack, varargin{:});
                else
                    [result, cache_info] = obj.LinkedDatasetChooser.GetResult(plugin_name, obj.DatasetStack, varargin{:});
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
        
        % Save data as a cache file associated with this dataset
        % Used for marker points
        function SaveData(obj, name, data, varargin)
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.SaveData(name, data, varargin{:});
            obj.PostCallTidy;
        end
        
        % Load data from a cache file associated with this dataset
        function data = LoadData(obj, name, varargin)
            obj.PreCallTidy;
            data = obj.LinkedDatasetChooser.LoadData(name, varargin{:});
            obj.PostCallTidy;
        end

        % Gets the path of the folder where the results for this dataset are
        % stored
        function dataset_cache_path = GetDatasetCachePath(obj, varargin)
            obj.PreCallTidy;
            dataset_cache_path = obj.LinkedDatasetChooser.GetCachePath(varargin{:});
            obj.PostCallTidy;
        end

        % Gets the path of the folder where the output files for this dataset are
        % stored
        function dataset_cache_path = GetOutputPathAndCreateIfNecessary(obj, varargin)
            obj.PreCallTidy;
            dataset_cache_path = obj.LinkedDatasetChooser.GetOutputPathAndCreateIfNecessary(varargin{:});
            obj.PostCallTidy;
        end
        
        % Returns a PTKImageInfo structure with image information, including the
        % UID, filenames and file path
        function image_info = GetImageInfo(obj, varargin)
            obj.PreCallTidy;
            image_info = obj.LinkedDatasetChooser.GetImageInfo(varargin{:});
            obj.PostCallTidy;
        end

        % Returns an empty template image for the specified context
        % See PTKImageTemplates.m for valid contexts
        function template_image = GetTemplateImage(obj, context, varargin)
            obj.PreCallTidy;
            template_image = obj.LinkedDatasetChooser.GetTemplateImage(context, obj.DatasetStack, varargin{:});
            obj.PostCallTidy;
        end
        
        % Gets a thumbnail image of the last result for this plugin
        function preview = GetPluginPreview(obj, plugin_name, varargin)
            % Note: we don't do any pre/post call tidying on this method, as we
            % permit it to be called while another call is in progress (which
            % may happen during a PreviewImageChanged notification).
            
            preview = obj.LinkedDatasetChooser.GetPluginPreview(plugin_name, varargin{:});
        end

        % Removes all the cache files associated with this dataset. Cache files
        % store the results of plugins so they need only be computed once for
        % each dataset. Clearing the cache files forces recomputation of all
        % results.
        function ClearCacheForThisDataset(obj, remove_framework_files, varargin)
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.ClearCacheForThisDataset(remove_framework_files, varargin{:});
            obj.PostCallTidy;
        end
        
        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context, varargin)
            obj.PreCallTidy;
            context_is_enabled = obj.LinkedDatasetChooser.IsContextEnabled(context, varargin{:});
            obj.PostCallTidy;
        end
        
        % Check if this is a hyperpolarised gas MRI image
        function is_gas_mri = IsGasMRI(obj, varargin)
            obj.PreCallTidy;
            is_gas_mri = obj.LinkedDatasetChooser.IsGasMRI(obj.DatasetStack, varargin{:});
            obj.PostCallTidy;
        end 
    end
    
    methods (Access = private)
        
        % Called before methods are executed in order to ensure the Framework is
        % in a tidy state after any previous error conditions
        function PreCallTidy(obj)
            obj.Reporting.ClearStack;
        end
        
        % Called after methods are executed in order to ensure the Framework is
        % in a tidy state after any previous error conditions
        function PostCallTidy(obj)
            obj.Reporting.ShowAndClear;
            obj.Reporting.ClearStack;
        end
    end
end