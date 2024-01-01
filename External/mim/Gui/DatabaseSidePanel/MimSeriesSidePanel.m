classdef MimSeriesSidePanel < GemListBoxWithTitle
    % MimSeriesSidePanel. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimSeriesSidePanel is part of the side panel and contains the sliding list
    %     box showing series
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    

    properties (Access = private)
        PatientDatabase        
        GuiCallback
        GroupPatientsWithSameName
    end
    
    methods
        function obj = MimSeriesSidePanel(parent, patient_database, group_patients_with_same_name, gui_callback)
            obj = obj@GemListBoxWithTitle(parent, 'SERIES', 'Import images', 'Delete images');
            
            obj.PatientDatabase = patient_database;
            obj.GuiCallback = gui_callback;
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
       
        function DeleteSelectedSeries(obj)
            obj.DeleteButtonClicked([], []);
        end
        
       function SelectNextSeries(obj)
            next_series_id = obj.ListBox.GetNextItemId;
            series_item = obj.ListBox.GetItem(next_series_id);
            if ~isempty(next_series_id)
                obj.GuiCallback.SeriesClicked(series_item.PatientId, next_series_id);
            end
        end
        
        function SelectPreviousSeries(obj)
            prev_series_id = obj.ListBox.GetPreviousItemId;
            series_item = obj.ListBox.GetItem(prev_series_id);
            if ~isempty(prev_series_id)
                obj.GuiCallback.SeriesClicked(series_item.PatientId, prev_series_id);
            end
        end        
    end
    
    methods (Access = protected)
        function AddButtonClicked(obj, ~, event_data)
            obj.GuiCallback.AddSeries;
        end
        
        function DeleteButtonClicked(obj, ~, ~)
            series_uid = obj.ListBox.GetListBox.SelectedTag;
            if ~isempty(series_uid)
                
                parent_figure = obj.GetParentFigure;
                parent_figure.ShowWaitCursor;
                obj.GuiCallback.DeleteSeries(series_uid);
                
                % Note that at this point it is possible obj may have been deleted, so we can no longer use it
                parent_figure.HideWaitCursor;
            end
        end
    end
    

    methods (Access = private)
        
        function AddSeriesToListBox(obj, patient_id, series_uid)
            datasets = obj.PatientDatabase.GetAllSeriesForThisPatient(obj.GuiCallback.GetCurrentProject, patient_id, obj.GroupPatientsWithSameName);
            obj.ListBox.ClearItems;
            
            for series_index = 1 : length(datasets)
                series = datasets{series_index};
                series_item = MimSidePanelSeriesDescription(obj.ListBox.GetListBox, series.Modality, series.StudyName, series.Name, series.Date, series.Time, series.NumberOfImages, patient_id, series.SeriesUid, obj.GuiCallback);
                
                obj.ListBox.AddItem(series_item);
            end
            
            obj.ListBox.SelectItem(series_uid, true);
        end
    end    
end