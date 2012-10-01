classdef TDLinkedDatasetChooser < handle
    % TDLinkedDatasetChooser. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     TDLinkedDatasetChooser is used to select between linked datasets.
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
        PrimaryDatasetResults % Handle to the TDDatasetResults object for this dataset
        LinkedDatasetChooserList % Handles to TDLinkedDatasetChooser objects for all linked datasets, including this one
        PrimaryDatasetUid     % The uid of this dataset
    end
    
    methods
        function obj = TDLinkedDatasetChooser(primary_dataset_results)
            obj.PrimaryDatasetUid = primary_dataset_results.GetImageInfo.ImageUid;
            obj.PrimaryDatasetResults = primary_dataset_results;
            obj.LinkedDatasetChooserList = containers.Map;
            obj.LinkedDatasetChooserList(obj.PrimaryDatasetUid) = obj;
        end
        
        function AddLinkedDataset(obj, linked_name, linked_dataset_chooser)
            linked_uid = linked_dataset_chooser.PrimaryDatasetUid;
            obj.LinkedDatasetChooserList(linked_uid) = linked_dataset_chooser;
            obj.LinkedDatasetChooserList(linked_name) = linked_dataset_chooser;
        end

        % RunPlugin: Returns the results of a plugin. If a valid result is cached on disk,
        % this wil be returned provided all the dependencies are valid.
        % Otherwise the plugin will be executed and the new result returned.
        % The optional context parameter specifies the region of interest to which the output result will be framed.
        % Specifying a second argument also produces a representative image from
        % the results. For plugins whose result is an image, this will generally be the
        % same as the results.
        function [result, output_image] = GetResult(obj, plugin_name, dataset_call_stack, context, dataset_uid)
            linked_dataset = obj.FindLinkedDatasetChooser(dataset_uid);
            dataset_callback = TDDatasetCallback(linked_dataset, dataset_call_stack);
            
            if nargout > 1
                [result, output_image] = linked_dataset.PrimaryDatasetResults.GetResult(plugin_name, dataset_callback, dataset_call_stack, context);
            else
                result = linked_dataset.PrimaryDatasetResults.GetResult(plugin_name, dataset_callback, dataset_call_stack, context);
            end
        end

        % Returns a TDImageInfo structure with image information, including the
        % UID, filenames and file path
        function image_info = GetImageInfo(obj, dataset_uid)
            image_info = obj.FindLinkedDatasetChooser(dataset_uid).PrimaryDatasetResults.GetImageInfo;
        end
        
        % Returns an empty template image for the specified context
        % See TDImageTemplates.m for valid contexts
        function template_image = GetTemplateImage(obj, context, dataset_uid)
            template_image = obj.FindLinkedDatasetChooser(dataset_uid).PrimaryDatasetResults.ImageTemplates.GetTemplateImage(context);
        end
        
        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context, dataset_uid)
            context_is_enabled = obj.FindLinkedDatasetChooser(dataset_uid).PrimaryDatasetResults.ImageTemplates.IsContextEnabled(context);
        end
        
        % ToDo: This check is based on series description and should be more
        % general
        function is_gas_mri = IsGasMRI(obj, dataset_uid)
            is_gas_mri = obj.FindLinkedDatasetChooser(dataset_uid).PrimaryDatasetResults.IsGasMRI;
        end
    end

    methods (Access = private)
        function linked_dataset_chooser = FindLinkedDatasetChooser(obj, dataset_uid)
            if isempty(dataset_uid)
                dataset_uid = obj.PrimaryDatasetUid;
            end
            linked_dataset_chooser = obj.LinkedDatasetChooserList(dataset_uid);
        end
    end
end
