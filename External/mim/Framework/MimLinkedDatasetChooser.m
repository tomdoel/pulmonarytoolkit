classdef MimLinkedDatasetChooser < CoreBaseClass
    % MimLinkedDatasetChooser. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     MimLinkedDatasetChooser is used to select between linked datasets.
    %     By default, each dataset acts independently, but you can link datasets
    %     together (for example, if you wanted to register images between two
    %     datasets). When datasets are linked, one is the primary dataset, and
    %     linked results are stored in the primary cache. The primary dataset
    %     may access results from any of its linked datasets (but not vice
    %     versa). Linking can be nested.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties (Access = private)
        LinkedRecorderSingleton
        DatasetCache
        PrimaryDatasetResults % Handle to the MimDatasetResults object for this dataset
        LinkedDatasetChooserList % Handles to MimLinkedDatasetChooser objects for all linked datasets, including this one
        PrimaryDatasetUid     % The uid of this dataset
    end
    
    events
        % This event is fired when a plugin has been run for this dataset, and
        % has generated a new preview thumbnail.
        PreviewImageChanged
    end
    
    methods
        function obj = MimLinkedDatasetChooser(framework_app_def, context_def, image_info, dataset_disk_cache, linked_recorder_singleton, plugin_cache, reporting)
            obj.LinkedRecorderSingleton = linked_recorder_singleton;
            obj.DatasetCache = dataset_disk_cache;
            primary_dataset_results = MimDatasetResults(framework_app_def, context_def, image_info, obj, obj, dataset_disk_cache, plugin_cache, reporting);
            obj.PrimaryDatasetUid = primary_dataset_results.GetImageInfo.ImageUid;
            obj.PrimaryDatasetResults = primary_dataset_results;
            obj.LinkedDatasetChooserList = containers.Map;
            obj.LinkedDatasetChooserList(obj.PrimaryDatasetUid) = obj;
        end

        function AddLinkedDataset(obj, linked_name, linked_dataset_chooser, reporting)
            % Links a different dataset to this one, using the specified name.
            % The name exists only within the scope of this dataset, and is used
            % to identify the linked dataset from which results should be
            % obtained.
            
            linked_uid = linked_dataset_chooser.PrimaryDatasetUid;
            obj.LinkedDatasetChooserList(linked_uid) = linked_dataset_chooser;
            obj.LinkedDatasetChooserList(linked_name) = linked_dataset_chooser;
            
            obj.LinkedRecorderSingleton.AddLink(obj.PrimaryDatasetUid, linked_uid, linked_name, reporting);
        end
        
        function dataset_results = GetDataset(obj, reporting, varargin)
            % Returns a handle to the DatasetResults object for a particular linked dataset.
            % The dataset is identified by its uid in varargin, or an empty
            % input will return the primary dataset.
            
            if nargin < 3
                dataset_name = [];
            else
                dataset_name = varargin{1};
            end
            if isempty(dataset_name)
                dataset_name = obj.PrimaryDatasetUid;
            end
            if ~obj.LinkedDatasetChooserList.isKey(dataset_name)
                reporting.Error('MimLinkedDatasetChooser:DatasetNotFound', 'No linked dataset was found with this name. Did you add the dataset with LinkDataset()?'); 
            end
            linked_dataset_chooser = obj.LinkedDatasetChooserList(dataset_name);            
            dataset_results = linked_dataset_chooser.PrimaryDatasetResults;
        end
        
        function is_linked_dataset = IsLinkedDataset(obj, linked_name_or_uid, reporting)
            % Returns true if another dataset has been linked to this one, using
            % the name or uid specified
            
            is_linked_dataset = obj.LinkedDatasetChooserList.isKey(linked_name_or_uid);
        end
        
        function ClearMemoryCacheInAllLinkedDatasets(obj)
            % Clears the temporary memory cache of this and all linked
            % datasets
            for linker = obj.LinkedDatasetChooserList.values
                if linker{1} == obj
                    obj.DatasetCache.ClearTemporaryMemoryCache;
                else
                    linker{1}.ClearMemoryCacheInAllLinkedDatasets;
                end
            end
        end
        
        function NotifyPreviewImageChanged(obj, plugin_name)
            notify(obj,'PreviewImageChanged', CoreEventData(plugin_name));
        end
    end
end
