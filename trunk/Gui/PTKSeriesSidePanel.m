classdef PTKSeriesSidePanel < PTKListBoxWithTitle
    % PTKSeriesSidePanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKSeriesSidePanel is part of the side panel and contains the sliding list
    %     box showing series
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
    end
    
    methods
        function obj = PTKSeriesSidePanel(parent, patient_database, gui_callback, reporting)
            obj = obj@PTKListBoxWithTitle(parent, 'SERIES', 'Import images', 'Delete images', reporting);
            
            obj.PatientDatabase = patient_database;
            obj.GuiCallback = gui_callback;
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
                obj.GuiCallback.DeleteDataset(series_uid);
                
                % Note that at this point it is possible obj may have been deleted, so we can no longer use it
                parent_figure.HideWaitCursor;
            end
        end
    end
    

    methods (Access = private)
        
        function AddSeriesToListBox(obj, patient_id, series_uid)
            datasets = obj.PatientDatabase.GetAllSeriesForThisPatient(patient_id);
            obj.ListBox.ClearItems;
            
            for series_index = 1 : length(datasets)
                series = datasets{series_index};
                series_item = PTKSidePanelSeriesDescription(obj.ListBox.GetListBox, series.Modality, series.StudyName, series.Name, series.Date, series.Time, series.NumberOfImages, patient_id, series.SeriesUid, obj.GuiCallback, obj.Reporting);
                
                obj.ListBox.AddItem(series_item);
            end
            
            obj.ListBox.SelectItem(series_uid, true);
        end
    end    
end