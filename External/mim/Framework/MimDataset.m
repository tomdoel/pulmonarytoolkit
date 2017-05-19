classdef MimDataset < CoreBaseClass
    % MimDataset. Use this class to obtain results and associated data for a particualar dataset.
    %
    %     This class is used by scripts and GUI applications to run
    %     calculations, fetch cached results and access data associated with a
    %     dataset. The difference between MimDataset and MimDatasetResults is that
    %     MimDataset is called from outside the toolkit, whereas MimDatasetResults
    %     is called by plugins during their RunPlugin() call. MimDataset
    %     calls MimDatasetResults, but provides additional progress and error
    %     reporting and dependency tracking.
    %
    %     Each dataset will have its own instance of MimDataset.
    %
    %     You should not create this class directly. Instead, create an instance of
    %     the class MimMain and use the methods CreateDatasetFromInfo and
    %     CreateDatasetFromUid to get a MimDataset object for each dataset you are
    %     working with.
    %
    %     Example: Replace <image path> and <filenames> with the path and filenames
    %     to your image data.
    %
    %         image_info = PTKImageInfo( <image path>, <filenames>, [], [], [], []);
    %         mim = MimMain;
    %         dataset = mim.CreateDatasetFromInfo(image_info);
    %
    %     You can then obtain results from this dataset, e.g.
    %
    %         results = dataset.GetResult('PluginName');
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        
        % Multiple datasets can be linked together. The LinkedDatasetChooser is
        % used to send API calls to the correct dataset.
        LinkedDatasetChooser
        
        % Manages the heirarchy (call stack) of plugins calling other plugins.
        % This is used for dependency checking and to prevent recursion.
        % Each MimDataset API has its own call stack which relates to the calls
        % being made at that interface. Note that when datasets are linked, one
        % dataset may end up calling another to fetch results; however, the same
        % call stack must be used for the dependency checking to work correctly.
        % This means that when a GetResult() call is
        % made on a dataset, the call stack depends not on which dataset is
        % being called, but where the call originated from. For this reason, the
        % call stacks are owned by the MimDataset class (where calls originate)
        % and passed through.
        DatasetStack
        
        % Object for error and progress reporting. MimDataset uses this to clean
        % up reporting in the case of error conditions.
        Reporting
    end
    
    events
        % This event is fired when a manual segmentaiion is added or
        % deleted for this dataset
        ManualSegmentationsChanged
        
        % This event is fired when a marker set is added or removed
        MarkersChanged
        
        % This event is fired when a plugin has been run for this dataset, and
        % has generated a new preview thumbnail.
        PreviewImageChanged
    end
    
    methods
        
        function obj = MimDataset(image_info, dataset_disk_cache, linked_dataset_chooser_factory, class_factory, reporting)
            % MimDataset is created by the MimMain class
            obj.DatasetStack = MimDatasetStack(class_factory);
            obj.Reporting = reporting;
            obj.LinkedDatasetChooser = linked_dataset_chooser_factory.GetLinkedDatasetChooser(image_info, dataset_disk_cache, reporting);
            
            % Listen for events - there could be
            % multiple MimDatasets linked to the same LinkedDatasetChooser
            obj.AddEventListener(dataset_disk_cache, 'MarkersChanged', @obj.MarkersChangedCallback);
            obj.AddEventListener(obj.LinkedDatasetChooser, 'PreviewImageChanged', @obj.PreviewImageChangedCallback);
            obj.AddEventListener(dataset_disk_cache, 'ManualSegmentationsChanged', @obj.ManualSegmentationsChangedCallback);
        end

        function LinkDataset(obj, linked_name, dataset_to_link)
            % Associates another dataset to this (e.g. multiple datasets for the
            % same patient)
            linked_dataset_chooser = dataset_to_link.LinkedDatasetChooser;
            obj.LinkedDatasetChooser.AddLinkedDataset(linked_name, linked_dataset_chooser, obj.Reporting);
        end

        function is_linked_dataset = IsLinkedDataset(obj, linked_name_or_uid)
            % Returns true if another dataset has been linked to this one, using
            % the name or uid specified
            
            is_linked_dataset = obj.LinkedDatasetChooser.IsLinkedDataset(linked_name_or_uid, obj.Reporting);
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
                    [result, cache_info, output_image] = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetResult(plugin_name, obj.DatasetStack, context, obj.Reporting, varargin{2:end});
                else
                    [result, cache_info] = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetResult(plugin_name, obj.DatasetStack, context, obj.Reporting, varargin{2:end});
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
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).SaveEditedResult(plugin_name, context, edited_result, obj.DatasetStack, obj.Reporting);
            obj.PostCallTidy;
        end
        
        function edited_result = GetDefaultEditedResult(obj, plugin_name, context, varargin)
            if nargin < 3
                context = [];
            end
            
            obj.PreCallTidy;
            edited_result = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetDefaultEditedResult(plugin_name, obj.DatasetStack, context, obj.Reporting);
            obj.PostCallTidy;
        end        

        function SaveData(obj, name, data, varargin)
            % Save data as a cache file associated with this dataset
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).SaveData(name, data, obj.Reporting);
            obj.PostCallTidy;
        end

        function data = LoadData(obj, name, varargin)
            % Load data from a cache file associated with this dataset
            obj.PreCallTidy;
            data = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).LoadData(name, obj.Reporting);
            obj.PostCallTidy;
        end

        function SaveManualSegmentation(obj, name, data, varargin)
            % Save data as a cache file associated with this dataset
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).SaveManualSegmentation(name, data, obj.DatasetStack, obj.Reporting);
            obj.PostCallTidy;
        end

        function data = LoadManualSegmentation(obj, name, varargin)
            % Load data from a cache file associated with this dataset
            obj.PreCallTidy;
            data = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).LoadManualSegmentation(name, obj.DatasetStack, obj.Reporting);
            obj.PostCallTidy;
        end
        
        function SaveMarkerPoints(obj, name, data, varargin)
            % Save data as a cache file associated with this dataset
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).SaveMarkerPoints(name, data, obj.DatasetStack, obj.Reporting);
            obj.PostCallTidy;
        end
        
        function DeleteMarkerSet(obj, name, varargin)
            % Deletes marker set
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).DeleteMarkerSet(name, obj.Reporting);
            obj.PostCallTidy;
        end

        function data = LoadMarkerPoints(obj, name, varargin)
            % Load data from a cache file associated with this dataset
            obj.PreCallTidy;
            data = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).LoadMarkerPoints(name, obj.DatasetStack, obj.Reporting);
            obj.PostCallTidy;
        end
        
        function dataset_cache_path = GetDatasetCachePath(obj, varargin)
            % Gets the path of the folder where the results for this dataset are stored
            obj.PreCallTidy;
            dataset_cache_path = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetDatasetCachePath(obj.Reporting);
            obj.PostCallTidy;
        end

        function dataset_cache_path = GetEditedResultsPath(obj, varargin)
            % Gets the path of the folder where the edited results for this dataset are stored
            obj.PreCallTidy;
            dataset_cache_path = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetEditedResultsPath(obj.Reporting);
            obj.PostCallTidy;
        end

        function dataset_cache_path = GetOutputPath(obj, varargin)
            % Gets the path of the folder where the output for this dataset are stored
            obj.PreCallTidy;
            dataset_cache_path = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetOutputPathAndCreateIfNecessary(obj.DatasetStack, obj.Reporting);
            obj.PostCallTidy;
        end

        function dataset_cache_path = GetOutputPathAndCreateIfNecessary(obj, varargin)
            % Gets the path of the folder where the output files for this dataset are stored
            obj.PreCallTidy;
            dataset_cache_path = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetOutputPathAndCreateIfNecessary(obj.DatasetStack, obj.Reporting);
            obj.PostCallTidy;
        end

        function image_info = GetImageInfo(obj, varargin)
            % Returns a PTKImageInfo structure with image information, including the
            % UID, filenames and file path
            obj.PreCallTidy;
            image_info = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetImageInfo(obj.Reporting);
            obj.PostCallTidy;
        end

        function template_image = GetTemplateImage(obj, context, varargin)
            % Returns an empty template image for the specified context
            % Valid contexts are specified via the AppDef file
            
            obj.PreCallTidy;
            template_image = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetTemplateImage(context, obj.DatasetStack, obj.Reporting);
            obj.PostCallTidy;
        end

        function template_image = GetTemplateMask(obj, context, varargin)
            % Returns a template image mask for the specified context
            % Valid contexts are specified via the AppDef file
            
            obj.PreCallTidy;
            template_image = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetTemplateMask(context, obj.DatasetStack, obj.Reporting);
            obj.PostCallTidy;
        end

        function preview = GetPluginPreview(obj, plugin_name, varargin)
            % Gets a thumbnail image of the last result for this plugin
            
            % Note: we don't do any pre/post call tidying on this method, as we
            % permit it to be called while another call is in progress (which
            % may happen during a PreviewImageChanged notification).
            
            preview = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetPluginPreview(plugin_name, obj.Reporting);
        end

        function ClearCacheForThisDataset(obj, remove_framework_files, varargin)
            % Removes all the cache files associated with this dataset.
            % Cache files store the results of plugins so they need only be computed once for
            % each dataset. Clearing the cache files forces recomputation of all
            % results.
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).ClearCacheForThisDataset(remove_framework_files, obj.Reporting);
            obj.PostCallTidy;
        end

        function DeleteCacheForThisDataset(obj, varargin)
            % Removes the cache file fodler associated with this dataset. This
            % should not be called unless you are completely removing the dataset
            
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).DeleteCacheForThisDataset(obj.Reporting);
            obj.PostCallTidy;
        end

        function DeleteEditedResult(obj, plugin_name, varargin)
            % Delete edit data from a cache file associated with this dataset
            
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).DeleteEditedPluginResult(plugin_name, obj.Reporting);
            obj.PostCallTidy;
        end

        function DeleteManualSegmentation(obj, segmentation_name, varargin)
            % Delete edit data from a cache file associated with this dataset
            
            obj.PreCallTidy;
            obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).DeleteManualSegmentation(segmentation_name, obj.Reporting);
            obj.PostCallTidy;
        end
        
        function file_list = GetListOfManualSegmentations(obj, varargin)
            % Gets list of manual segmentation files associated with this dataset
            
            obj.PreCallTidy;
            file_list = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetListOfManualSegmentations;
            obj.PostCallTidy;
        end
        
        function file_list = GetListOfMarkerSets(obj, varargin)
            % Gets list of manual segmentation files associated with this dataset
            
            obj.PreCallTidy;
            file_list = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetListOfMarkerSets;
            obj.PostCallTidy;
        end
        
        function context_is_enabled = IsContextEnabled(obj, context, varargin)
            % Check to see if a context has been disabled for this dataset, due to a
            % failure when running the plugin that generates the template image for
            % that context.
            
            obj.PreCallTidy;
            context_is_enabled = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).IsContextEnabled(context, obj.Reporting);
            obj.PostCallTidy;
        end

        function is_gas_mri = IsGasMRI(obj, varargin)
            % Check if this is a hyperpolarised gas MRI image
            
            obj.PreCallTidy;
            is_gas_mri = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).IsGasMRI(obj.DatasetStack, obj.Reporting);
            obj.PostCallTidy;
        end
        
        function patient_name = GetPatientName(obj, varargin)
            % Returns a single string for identifying the patient. The 
            % format will depend on what information is available in the
            % file metadata.

            patient_name = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetPatientName(obj.DatasetStack, obj.Reporting);
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
            
            % Clear all temporary memory caches
            obj.LinkedDatasetChooser.ClearMemoryCacheInAllLinkedDatasets;
            
            obj.Reporting.ShowAndClearPendingMessages;
            obj.Reporting.ClearProgressStack;
        end
        
        function PreviewImageChangedCallback(obj, ~, event_data)
            % Fire an event indictaing the preview image has changed. This
            % will allow any listening gui to update its preview images if
            % necessary
            obj.notify('PreviewImageChanged', CoreEventData(event_data.Data));
        end
        
        function MarkersChangedCallback(obj, ~, event_data)
            % Fire an event indictaing the manual segmentation list has changed. This
            % will allow any listening gui to update if necessary
            obj.notify('MarkersChanged', CoreEventData(event_data.Data));
        end
        
        function ManualSegmentationsChangedCallback(obj, ~, event_data)
            % Fire an event indictaing the manual segmentation list has changed. This
            % will allow any listening gui to update if necessary
            obj.notify('ManualSegmentationsChanged', CoreEventData(event_data.Data));
        end
        
        function contexts = GetAllContextsForManualSegmentations(obj, varargin)
            contexts = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, varargin{:}).GetAllContextsForManualSegmentations(obj.DatasetStack, obj.Reporting);
        end
    end
end