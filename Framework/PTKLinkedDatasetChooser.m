classdef PTKLinkedDatasetChooser < PTKBaseClass
    % PTKLinkedDatasetChooser. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     PTKLinkedDatasetChooser is used to select between linked datasets.
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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties (Access = private)
        LinkedRecorderSingleton
        PrimaryDatasetResults % Handle to the PTKDatasetResults object for this dataset
        LinkedDatasetChooserList % Handles to PTKLinkedDatasetChooser objects for all linked datasets, including this one
        PrimaryDatasetUid     % The uid of this dataset
    end
    
    events
        % This event is fired when a plugin has been run for this dataset, and
        % has generated a new preview thumbnail.
        PreviewImageChanged
    end
    
    methods
        function obj = PTKLinkedDatasetChooser(image_info, dataset_disk_cache, linked_recorder_singleton, reporting)
            obj.LinkedRecorderSingleton = linked_recorder_singleton;
            primary_dataset_results = PTKDatasetResults(image_info, obj, @obj.notify, dataset_disk_cache, reporting);
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
            
            dataset_results = obj.FindLinkedDatasetChooser(reporting, varargin{:}).PrimaryDatasetResults;
        end
        
        function is_linked_dataset = IsLinkedDataset(obj, linked_name_or_uid, reporting)
            % Returns true if another dataset has been linked to this one, using
            % the name or uid specified
            
            is_linked_dataset = obj.LinkedDatasetChooserList.isKey(linked_name_or_uid);
        end
    end

    methods (Access = private)
        function linked_dataset_chooser = FindLinkedDatasetChooser(obj, reporting, varargin)
            if nargin < 3
                dataset_name = [];
            else
                dataset_name = varargin{1};
            end
            if isempty(dataset_name)
                dataset_name = obj.PrimaryDatasetUid;
            end
            if ~obj.LinkedDatasetChooserList.isKey(dataset_name)
                reporting.Error('PTKLinkedDatasetChooser:DatasetNotFound', 'No linked dataset was found with this name. Did you add the dataset with LinkDataset()?'); 
            end
            linked_dataset_chooser = obj.LinkedDatasetChooserList(dataset_name);
        end
    end
end
