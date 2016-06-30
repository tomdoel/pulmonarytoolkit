classdef MimDatasetCallback < handle
    % MimDatasetCallback. Used by plugins to obtain results and associated data for a particular dataset.
    %
    %     This class is used by plugins to run calculations and fetch cached
    %     results associated with a dataset. The difference between MimDataset 
    %     and MimDatasetCallback is that MimDataset is called from outside the 
    %     toolkit, whereas MimDatasetCallback is called by plugins during their 
    %     RunPlugin() call. MimDataset calls MimDatasetCallback, but provides 
    %     additional progress and error reporting and dependency tracking.
    %
    %     You should not create this class directly. An instance of this class
    %     is given to plugins during their RunPlugin() function call.
    %
    %     Example: 
    %
    %     classdef MyPlugin < MimPlugin
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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    

    properties (Access = private)
        LinkedDatasetChooser  % Sends the API calls to the correct dataset
        DatasetStack          % Handle to the current call stack for the primary dataset
        DefaultContext        % The context for any results requested
        Reporting
    end
    
    methods
        function obj = MimDatasetCallback(linked_dataset_chooser, dataset_call_stack, default_context, reporting)
            obj.DatasetStack = dataset_call_stack;
            obj.LinkedDatasetChooser = linked_dataset_chooser;
            obj.DefaultContext = default_context;
            obj.Reporting = reporting;
        end
        
        function is_linked_dataset = IsLinkedDataset(obj, linked_name_or_uid)
            % Returns true if another dataset has been linked to this one, using
            % the name or uid specified
            
            is_linked_dataset = obj.LinkedDatasetChooser.IsLinkedDataset(linked_name_or_uid, obj.Reporting);
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
                [result, ~, output_image] = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetResult(plugin_name, obj.DatasetStack, context, obj.Reporting, []);
            else
                [result, ~] = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetResult(plugin_name, obj.DatasetStack, context, obj.Reporting, []);
            end
        end

        function image_info = GetImageInfo(obj, varargin)
            % Returns a MimImageInfo structure with image information, including the
            % UID, filenames and file path
            
            image_info = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetImageInfo(obj.Reporting);
        end
        
        function patient_name = GetPatientName(obj, varargin)
            % Returns a single string for identifying the patient. The format will depend on what information is available in the file metadata.
            
            patient_name = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetPatientName(obj.DatasetStack, obj.Reporting);
        end
        
        function template_image = GetTemplateImage(obj, context, varargin)
            % Returns an empty template image for the specified context
            % Valid contexts are specified via the AppDef file
            
            template_image = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetTemplateImage(context, obj.DatasetStack, obj.Reporting);
        end
        
        function template_image = GetTemplateMask(obj, context, varargin)
            % Returns a template image mask for the specified context
            % Valid contexts are specified via the AppDef file
            
            template_image = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetTemplateMask(context, obj.DatasetStack, obj.Reporting);
        end
        
        function context_is_enabled = IsContextEnabled(obj, context, varargin)
            % Check to see if a context has been disabled for this dataset, due to a
            % failure when running the plugin that generates the template image for
            % that context.
        
            context_is_enabled = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).IsContextEnabled(context, obj.Reporting);
        end
        
        function is_gas_mri = IsGasMRI(obj, varargin)
            % Returns if this dataset is a gas MRI type
            
            is_gas_mri = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).IsGasMRI(obj.DatasetStack, obj.Reporting);
        end
        
        function dataset_cache_path = GetOutputPathAndCreateIfNecessary(obj, varargin)
            % Gets the path of the folder where the output files for this dataset are
            % stored
            
            dataset_cache_path = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetOutputPathAndCreateIfNecessary(obj.DatasetStack, obj.Reporting);
        end
        
        function SaveTableAsCSV(obj, plugin_name, subfolder_name, file_name, description, table, file_dim, row_dim, col_dim, filters, varargin)
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).SaveTableAsCSV(plugin_name, subfolder_name, file_name, description, table, file_dim, row_dim, col_dim, filters, obj.DatasetStack, obj.Reporting);
        end

        function SaveFigure(obj, figure_handle, plugin_name, subfolder_name, file_name, description, varargin)
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).SaveFigure(figure_handle, plugin_name, subfolder_name, file_name, description, obj.DatasetStack, obj.Reporting);
        end

        function SaveSurfaceMesh(obj, plugin_name, subfolder_name, file_name, description, segmentation, smoothing_size, small_structures, coordinate_system, template_image, varargin)
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).SaveSurfaceMesh(plugin_name, subfolder_name, file_name, description, segmentation, smoothing_size, small_structures, coordinate_system, template_image, obj.DatasetStack, obj.Reporting);
        end

        function RecordNewFileAdded(obj, plugin_name, file_path, file_name, description, varargin)
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).RecordNewFileAdded(plugin_name, file_path, file_name, description, obj.Reporting)
        end        
    end
end
