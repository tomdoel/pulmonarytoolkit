classdef PTKLinkedSeriesSidePanel < PTKListBoxWithTitle
    % PTKLinkedSeriesSidePanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKLinkedSeriesSidePanel is part of the side panel and contains the sliding list
    %     box showing linked series
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    properties (Access = private)
        PatientDatabase
        GuiCallback
        LinkedRecorder
    end
    
    methods
        function obj = PTKLinkedSeriesSidePanel(parent, patient_database, linked_recorder, gui_callback, reporting)
            obj = obj@PTKListBoxWithTitle(parent, 'LINKED SERIES', 'Import images', 'Delete images', reporting);
            
            obj.PatientDatabase = patient_database;
            obj.GuiCallback = gui_callback;
            obj.LinkedRecorder = linked_recorder;
        end
        
        function RepopulateSidePanel(obj, patient_id, series_uid)
            obj.AddSeriesToListBox(patient_id, series_uid);
            if obj.ComponentHasBeenCreated
                obj.Resize(obj.Position);
            end
        end
        
        function UpdateSidePanel(obj, series_uid)
            obj.ListBox.SelectItem(series_uid, true);
        end
        
        function SelectSeries(obj, series_uid, selected)
            obj.ListBox.SelectItem(series_uid, selected);
        end
        
    end
    
    methods (Access = protected)
        function AddButtonClicked(obj, ~, event_data)
            obj.GuiCallback.ImportMultipleFiles;
        end
        
        function DeleteButtonClicked(obj, ~, event_data)
            series_uid = obj.ListBox.GetListBox.SelectedTag;
            if ~isempty(series_uid)
                parent_figure = obj.GetParentFigure;
                parent_figure.ShowWaitCursor;
                obj.GuiCallback.UnlinkDataset(series_uid);
                parent_figure.HideWaitCursor;
            end
        end
    end
    
    
    methods (Access = private)
        
        function AddSeriesToListBox(obj, patient_id, series_uid)
            
            % Get uids for every series associated with this patient
            datasets = obj.PatientDatabase.GetAllSeriesForThisPatient(patient_id);
            uids = PTKContainerUtilities.GetFieldValuesFromSet(datasets, 'SeriesUid');
            obj.ListBox.ClearItems;
            
            link_map = obj.LinkedRecorder.LinkMap;
            linked_uids_list = {};
            for uid = uids
                if link_map.isKey(uid{1})
                    link_record = link_map(uid{1});
                    linked_uids_list{end + 1} = uid{1};
                    linked_uids_list = [linked_uids_list, link_record.LinkMap.keys];
                end
            end
            
            if ~isempty(linked_uids_list)
                % Extract only the series which are part of thr linked list map
                [uid_found_map, series_index] = ismember(linked_uids_list, uids);
                linked_series = datasets(series_index(uid_found_map));
                
                
                for series_index = 1 : length(linked_series)
                    series = linked_series{series_index};
                    series_item = PTKSidePanelLinkedSeriesDescription(obj.ListBox.GetListBox, series.Modality, series.StudyName, series.Name, series.Date, series.Time, series.NumberOfImages, patient_id, series.SeriesUid, obj.GuiCallback, obj.Reporting);
                    
                    obj.ListBox.AddItem(series_item);
                end
                
                obj.ListBox.SelectItem(series_uid, true);
            end
        end
    end
end