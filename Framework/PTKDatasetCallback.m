classdef PTKDatasetCallback < handle
    % PTKDatasetCallback. Used by plugins to obtain results and associated data for a particular dataset.
    %
    %     This class is used by plugins to run calculations and fetch cached
    %     results associated with a dataset. The difference between PTKDataset 
    %     and PTKDatasetCallback is that PTKDataset is called from outside the 
    %     toolkit, whereas PTKDatasetCallback is called by plugins during their 
    %     RunPlugin() call. PTKDataset calls PTKDatasetCallback, but provides 
    %     additional progress and error reporting and dependency tracking.
    %
    %     You should not create this class directly. An instance of this class
    %     is given to plugins during their RunPlugin() function call.
    %
    %     Example: 
    %
    %     classdef MyPlugin < PTKPlugin
    %
    %     methods (Static)
    %         function results = RunPlugin(dataset_callback, reporting)
    %             ...
    %             airway_results = dataset_callback.GetResult('PTKAirways');
    %             ...
    %         end
    %     end
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    

    properties (Access = private)
        LinkedDatasetChooser  % Sends the API calls to the correct dataset
        DatasetStack          % Handle to the current call stack for the primary dataset
        DefaultContext        % The context for any results requested
    end
    
    methods
        function obj = PTKDatasetCallback(linked_dataset_chooser, dataset_call_stack, default_context)
            obj.DatasetStack = dataset_call_stack;
            obj.LinkedDatasetChooser = linked_dataset_chooser;
            obj.DefaultContext = default_context;
        end

        function [result, output_image] = GetResult(obj, plugin_name, context, varargin)
            % RunPlugin: Returns the results of a plugin.
            % If a valid result is cached on disk,
            % this wil be returned provided all the dependencies are valid.
            % Otherwise the plugin will be executed and the new result returned.
            % The optional context parameter specifies the region of interest to which the output result will be framed.
            % The dataset_uid argument specifies the name (or UID) of the linked
            % dataset from which the result will be fetched - if empty or not
            % specified then the primary dataset is used.
            % Specifying a second output argument produces a representative image from
            % the results. For plugins whose result is an image, this will generally be the
            % same as the results.
        
            if nargin < 3
                context = [];
            end
            
            if nargout > 1
                [result, ~, output_image] = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetResult(plugin_name, obj.DatasetStack, context, []);
            else
                [result, ~] = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetResult(plugin_name, obj.DatasetStack, context, []);
            end
        end

        function image_info = GetImageInfo(obj, varargin)
            % Returns a PTKImageInfo structure with image information, including the
            % UID, filenames and file path
            
            image_info = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetImageInfo;
        end
        
        function template_image = GetTemplateImage(obj, context, varargin)
            % Returns an empty template image for the specified context
            % See PTKImageTemplates.m for valid contexts
            
            template_image = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetTemplateImage(context, obj.DatasetStack);
        end
        
        function context_is_enabled = IsContextEnabled(obj, context, varargin)
            % Check to see if a context has been disabled for this dataset, due to a
            % failure when running the plugin that generates the template image for
            % that context.
        
            context_is_enabled = obj.LinkedDatasetChooser.GetDataset(varargin{:}).IsContextEnabled(context);
        end
        
        function is_gas_mri = IsGasMRI(obj, varargin)
            % Returns if this dataset is a gas MRI type
            
            is_gas_mri = obj.LinkedDatasetChooser.GetDataset(varargin{:}).IsGasMRI(obj.DatasetStack);
        end
        
        function dataset_cache_path = GetOutputPathAndCreateIfNecessary(obj, varargin)
            % Gets the path of the folder where the output files for this dataset are
            % stored
            
            dataset_cache_path = obj.LinkedDatasetChooser.GetDataset(varargin{:}).GetOutputPathAndCreateIfNecessary;
        end        
    end
end
