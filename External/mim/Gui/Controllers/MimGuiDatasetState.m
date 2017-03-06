classdef MimGuiDatasetState < CoreBaseClass
    % MimGuiDatasetState. Stores information about the currently loaded series
    %
    %     You do not need to modify this file. To add new functionality, create
    %     new plguins in the Plugins and GuiPlugins folders.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        CurrentSeriesUid
        CurrentPatientId
        CurrentPatientVisibleName
        CurrentSeriesName
        CurrentModality
        
        CurrentPluginInfo
        CurrentPluginName
        CurrentVisiblePluginName
        CurrentPluginResultIsEdited
        
        CurrentSegmentationName
    end
    
    events
        SeriesUidChangedEvent
        PatientIdChangedEvent
        PluginChangedEvent

        ManualSegmentationsChanged % Manual segmentations changed for current dataset
        PreviewImageChanged % Preview images changed for current dataset
        MarkersChanged % Markers changed for current dataset
    end
    
    methods
        function SetPatientAndSeries(obj, patient_id, series_uid, patient_visible_name, series_name, modality)
            
            if ~strcmp(patient_id, obj.CurrentPatientId) || ~strcmp(series_uid, obj.CurrentSeriesUid)
                obj.CurrentPatientId = patient_id;
                obj.CurrentSeriesUid = series_uid;
                obj.CurrentPatientVisibleName = patient_visible_name;
                obj.CurrentSeriesName = series_name;
                obj.CurrentModality = modality;
                notify(obj, 'SeriesUidChangedEvent', CoreEventData(series_uid));
            end
        end
        
        function SetPatientClearSeries(obj, patient_id, patient_visible_name)
            patient_changed = ~strcmp(patient_id, obj.CurrentPatientId);
            series_changed = ~isempty(obj.CurrentSeriesUid);
            obj.CurrentPatientId = patient_id;
            obj.CurrentSeriesUid = [];
            obj.CurrentPatientVisibleName = patient_visible_name;
            obj.CurrentSeriesName = [];
            obj.CurrentModality = [];
            if series_changed
                notify(obj, 'SeriesUidChangedEvent', CoreEventData([]));
            elseif patient_changed
                notify(obj, 'PatientIdChangedEvent', CoreEventData(patient_id));
            end
        end
        
        function ClearSeries(obj)
            if ~isempty(obj.CurrentPatientId) || ~isempty(obj.CurrentSeriesUid)
                obj.CurrentSeriesUid = [];
                obj.CurrentSeriesName = [];
                obj.CurrentModality = [];
                obj.CurrentSegmentationName = [];
                notify(obj, 'SeriesUidChangedEvent', CoreEventData([]));
            end
        end
        
        function ClearPatientAndSeries(obj)
            if ~isempty(obj.CurrentPatientId) || ~isempty(obj.CurrentSeriesUid)
                obj.CurrentPatientId = [];
                obj.CurrentSeriesUid = [];
                obj.CurrentPatientVisibleName = [];
                obj.CurrentSeriesName = [];
                obj.CurrentModality = [];
                obj.CurrentSegmentationName = [];
                notify(obj, 'SeriesUidChangedEvent', CoreEventData([]));
            end
        end
        
        function ClearPlugin(obj)
            obj.CurrentPluginInfo = [];
            obj.CurrentPluginName = [];
            obj.CurrentVisiblePluginName = [];
            obj.CurrentPluginResultIsEdited = false;
            obj.CurrentSegmentationName = [];
            notify(obj, 'PluginChangedEvent', CoreEventData([]));
        end
        
        function SetPlugin(obj, plugin_info, plugin_name, plugin_visible_name, is_edited)
            obj.CurrentPluginInfo = plugin_info;
            obj.CurrentPluginName = plugin_name;
            obj.CurrentVisiblePluginName = plugin_visible_name;
            obj.CurrentPluginResultIsEdited = is_edited;
            obj.CurrentSegmentationName = [];
            notify(obj, 'PluginChangedEvent', CoreEventData(plugin_name));
        end
        
        function SetSegmentation(obj, segmentation_name)
            obj.ClearPlugin;
            obj.CurrentSegmentationName = segmentation_name;
            notify(obj, 'PluginChangedEvent', CoreEventData(segmentation_name));
        end
        
        function UpdateEditStatus(obj, is_edited)
            if ~isequal(obj.CurrentPluginResultIsEdited, is_edited)
                obj.CurrentPluginResultIsEdited = is_edited;
                notify(obj, 'PluginChangedEvent', CoreEventData(obj.CurrentPluginName));
            end
        end
    end
end