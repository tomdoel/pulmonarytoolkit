classdef MimLinkedDatasetRecorder < CoreBaseClass
    % MimLinkedDatasetRecorder. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     MimLinkedDatasetRecorder is used to cache links between datasets for
    %     multimodal analysis. Links can be explicitly made using the MimDataset API
    %     call LinkDataset(). This class caches such links so that they can be made
    %     automatically.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        LinkMap % Maps all the links to this dataset
        
        AssociatedDatasetsMap % Maps all the datasets which link to this dataset
    end
    
    properties (Transient, Access = private)
        FrameworkAppDef
    end
        
    events
        LinkingChanged
    end
    
    methods (Static)
        function linked_recorder = Load(framework_app_def, reporting)
            try
                linked_recorder_filename = framework_app_def.GetFrameworkDirectories.GetLinkingCacheFilePath;
                if exist(linked_recorder_filename, 'file')
                    legacy_conversion = containers.Map;
                    legacy_conversion('PTKLinkedDatasetRecorder') = 'MimLinkedDatasetRecorder';
                    legacy_conversion('PTKLinkedDatasetCacheRecord') = 'MimLinkedDatasetCacheRecord';
                    legacy_conversion('PTKLinkedDatasetAssociatedDatasetRecord') = 'MimLinkedDatasetAssociatedDatasetRecord';
                    linked_recorder = CoreLoadXml(linked_recorder_filename, reporting, legacy_conversion);
                    linked_recorder = linked_recorder.LinkingCache;
                else
                    reporting.ShowWarning('MimLinkedDatasetRecorder:LinkedRecorderFileNotFound', 'No linking cache file found. Will create new one on exit', []);
                    linked_recorder = MimLinkedDatasetRecorder;
                    linked_recorder.Save(reporting);
                end
                linked_recorder.FrameworkAppDef = framework_app_def;
            catch ex
                reporting.ShowWarning('MimLinkedDatasetRecorder:FailedtoLoadCacheFile', ['Error when loading cache file ' linked_recorder_filename '. Any existing links between datasets will be lost'], ex);
                linked_recorder = MimLinkedDatasetRecorder;
            end
        end
        
    end    
    
    methods
        function obj = MimLinkedDatasetRecorder
            obj.LinkMap = containers.Map;
            obj.AssociatedDatasetsMap = containers.Map;
        end

        function is_primary = IsPrimaryDataset(obj, series_uid)
            is_primary = obj.LinkMap.isKey(series_uid);
        end
        
        function RemoveLink(obj, secondary_uid, reporting)
            
            % Remove all links to this dataset
            if obj.AssociatedDatasetsMap.isKey(secondary_uid)
                associated_map = obj.AssociatedDatasetsMap(secondary_uid);
                primary_uids = associated_map.AssociatedDatasetsList;
                
                for primary_uid_cell = primary_uids
                    primary_uid = primary_uid_cell{1};
                    if obj.LinkMap.isKey(primary_uid)
                        link_record = obj.LinkMap(primary_uid);
                        link_record.RemoveLink(secondary_uid);
                        if link_record.IsEmpty
                            obj.LinkMap.remove(primary_uid);
                        end
                    end
                end
                
                associated_map.RemoveLink(secondary_uid);
            end

            % If this is a primary dataset, remove all links
            if obj.LinkMap.isKey(secondary_uid)
                obj.LinkMap.remove(secondary_uid);
            end            
            
            obj.Save(reporting);
            
            notify(obj, 'LinkingChanged', CoreEventData(secondary_uid));
        end
        
        function AddLink(obj, primary_uid, secondary_uid, name, reporting)
            if obj.LinkMap.isKey(primary_uid)
                link_record = obj.LinkMap(primary_uid);
            else
                link_record = MimLinkedDatasetCacheRecord;
                obj.LinkMap(primary_uid) = link_record;
            end
            
            link_record.AddLink(name, secondary_uid);
            
            if ~obj.AssociatedDatasetsMap.isKey(secondary_uid)
                obj.AssociatedDatasetsMap(secondary_uid) = MimLinkedDatasetAssociatedDatasetRecord;
            end
            
            associated_map = obj.AssociatedDatasetsMap(secondary_uid);
            associated_map.AddLink(primary_uid);
            
            obj.Save(reporting);
            
            notify(obj, 'LinkingChanged', CoreEventData(secondary_uid));
        end
        

        function Save(obj, reporting)
            cache_filename = obj.FrameworkAppDef.GetFrameworkDirectories.GetLinkingCacheFilePath;
            
            try
                value = [];
                value.cache = obj;
                CoreSaveXml(obj, 'LinkingCache', cache_filename, reporting);
            catch ex
                reporting.ErrorFromException('MimLinkedDatasetRecorder:FailedtoSaveCacheFile', ['Unable to save linking cache file ' cache_filename], ex);
            end
        end        
    end
end