classdef MimLinkedSeriesSidePanel < GemListBoxWithTitle
    % MimLinkedSeriesSidePanel. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimLinkedSeriesSidePanel is part of the side panel and contains the sliding list
    %     box showing linked series
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    
    properties (Access = private)
        PatientDatabase
        GuiCallback
        LinkedRecorder
        GroupPatientsWithSameName
    end
    
    methods
        function obj = MimLinkedSeriesSidePanel(parent, patient_database, linked_recorder, group_patients_with_same_name, gui_callback)
            obj = obj@GemListBoxWithTitle(parent, 'LINKED SERIES', 'Import images', 'Delete images');
            
            obj.PatientDatabase = patient_database;
            obj.GuiCallback = gui_callback;
            obj.LinkedRecorder = linked_recorder;
            obj.GroupPatientsWithSameName = group_patients_with_same_name;
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
            datasets = obj.PatientDatabase.GetAllSeriesForThisPatient(obj.GuiCallback.GetCurrentProject, patient_id, obj.GroupPatientsWithSameName);
            all_uids = CoreContainerUtilities.GetFieldValuesFromSet(datasets, 'SeriesUid');
            obj.ListBox.ClearItems;
            
            link_map = obj.LinkedRecorder.LinkMap;
            linked_uids_list = {};
            linked_name_list = {};
            for uid = all_uids
                if link_map.isKey(uid{1})
                    link_record = link_map(uid{1});
                    linked_uids_list{end + 1} = uid{1};
                    linked_name_list{end + 1} = MimLinkedSeriesSidePanel.GuessPrimaryName(link_record);
                    
                    linked_uids_list = [linked_uids_list, link_record.LinkMap.keys];
                    linked_name_list = [linked_name_list, link_record.LinkMap.values];
                end
            end
            
            if ~isempty(linked_uids_list)
                % Extract only the series which are part of the linked list map
                [uid_found_map, series_index] = ismember(linked_uids_list, all_uids);
                linked_series = datasets(series_index(uid_found_map));
                                
                for series_index = 1 : length(linked_series)
                    series = linked_series{series_index};
                    link_name_text = linked_name_list{series_index};
                    series_item = MimSidePanelLinkedSeriesDescription(obj.ListBox.GetListBox, series.Modality, series.StudyName, series.Name, series.Date, series.Time, series.NumberOfImages, patient_id, series.SeriesUid, link_name_text, obj.GuiCallback);
                    
                    obj.ListBox.AddItem(series_item);
                end
                
                obj.ListBox.SelectItem(series_uid, true);
            end
        end
    end
    
    methods (Static, Access = private)
        function name = GuessPrimaryName(link_record)
            % The primary dataset in a set of links does not have a name, but it is useful
            % to assign one as a visual clue in the GUI
            name = 'Primary';
            names = link_record.LinkMap.values();
            if ismember('MR', names) && ismember('CT', names)
                name = 'XE';
            end
        end
    end
end