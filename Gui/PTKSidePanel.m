classdef PTKSidePanel < PTKPanel
    % PTKSidePanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKSidePanel represents the panel showing patients and series at the
    %     left side of the PTK GUI.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        SidePanelAxes
        PatientsSidePanel
        ProtocolSidePanel
        SeriesSidePanel
        PatientInfoSidePanel
        PatientNameTextControl
        SeriesDescriptions
        GuiState
        
        CurrentPatientId
    end
    
    properties (Constant, Access = private)
        PatientNameFontSize = 40
        PatientNameHeight = 40
        PatientNameWidth = 200
        PatientNameLeftPadding = 10        
        BorderSpace = 10
        SpacingBetweenLists = 20
    end
    
    methods
        function obj = PTKSidePanel(parent, patient_database, state, gui_callback, reporting)
            obj = obj@PTKPanel(parent, reporting);
            
            obj.GuiState = state;
            obj.SidePanelAxes = PTKLineAxes(obj, 'right');
            obj.SidePanelAxes.SetLimits([1, 1], [1, 1]);
            obj.AddChild(obj.SidePanelAxes, obj.Reporting);
            
            obj.PatientsSidePanel = PTKPatientsSidePanel(obj, patient_database, gui_callback, reporting);
            obj.AddChild(obj.PatientsSidePanel, obj.Reporting);
            
            obj.SeriesSidePanel = PTKSeriesSidePanel(obj, patient_database, gui_callback, reporting);
            obj.AddChild(obj.SeriesSidePanel, obj.Reporting);
            
            obj.Repopulate;

            % Add listener for changes to the loaded series
            obj.AddEventListener(obj.GuiState, 'SeriesUidChangedEvent', @obj.SeriesChanged);            
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKPanel(obj, position, reporting);
        end
        
        function Resize(obj, new_position)
            Resize@PTKPanel(obj, new_position);
            obj.SidePanelAxes.Resize(new_position);
            
            new_position(3) = new_position(3) - 2;
            
            available_height = new_position(4) - obj.SpacingBetweenLists;
            patients_panel_height = obj.PatientsSidePanel.GetRequestedHeight(new_position(3));
            series_panel_height = obj.SeriesSidePanel.GetRequestedHeight(new_position(3));
            half_height = round(available_height/2);
            
            if (patients_panel_height + series_panel_height) > available_height                
                if (series_panel_height < half_height)
                    patients_panel_height = available_height - series_panel_height;
                elseif (patients_panel_height > half_height)
                    patients_panel_height = half_height;
                end
            end
            series_panel_height = available_height - patients_panel_height;
            
            
            patients_position = new_position;
            patients_position(4) = patients_panel_height;
            patients_position(2) = patients_position(2) + series_panel_height + obj.SpacingBetweenLists;
            series_position = new_position;
            series_position(4) = series_panel_height;
            
            obj.PatientsSidePanel.Resize(patients_position);
            obj.SeriesSidePanel.Resize(series_position);
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.PanelHeight;
        end
        
        function DatabaseHasChanged(obj)
            obj.Repopulate;
        end
        
        function Repopulate(obj)
            obj.PatientsSidePanel.RepopulateSidePanel(obj.GuiState.CurrentPatientId);
            obj.SeriesSidePanel.RepopulateSidePanel(obj.GuiState.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
            if obj.ComponentHasBeenCreated
                obj.Resize(obj.Position);
            end
        end
        
        function UpdateSidePanel(obj, patient_id, series_uid)
            obj.SeriesSidePanel.RepopulateSidePanel(patient_id, series_uid);
        end
        
    end
    
    methods (Access = private)
        function SeriesChanged(obj, ~, ~)
            % This event fires when the loaded series has been changed.
            
            if ~strcmp(obj.GuiState.CurrentPatientId, obj.CurrentPatientId)
                % If the patient has changed, we need to repopulate the series list and change
                % the highlighted patient
                obj.PatientsSidePanel.UpdateSidePanel(obj.GuiState.CurrentPatientId);
                obj.SeriesSidePanel.RepopulateSidePanel(obj.GuiState.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
                
            else
                % Otherwise, we only need to change the highlighted series
                obj.SeriesSidePanel.UpdateSidePanel(obj.GuiState.CurrentSeriesUid);                
            end
            
            obj.CurrentPatientId = obj.GuiState.CurrentPatientId;
        end
        
    end
end