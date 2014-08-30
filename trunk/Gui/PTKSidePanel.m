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
        LinkedSeriesSidePanel
        PatientInfoSidePanel
        PatientNameTextControl
        SeriesDescriptions
        GuiState
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
        function obj = PTKSidePanel(parent, patient_database, state, linked_recorder, gui_callback, reporting)
            obj = obj@PTKPanel(parent, reporting);
            
            obj.GuiState = state;
            obj.SidePanelAxes = PTKLineAxes(obj, 'right');
            obj.SidePanelAxes.SetLimits([1, 1], [1, 1]);
            obj.AddChild(obj.SidePanelAxes, obj.Reporting);
            
            obj.PatientsSidePanel = PTKPatientsSidePanel(obj, patient_database, gui_callback, reporting);
            obj.AddChild(obj.PatientsSidePanel, obj.Reporting);
            
            obj.LinkedSeriesSidePanel = PTKLinkedSeriesSidePanel(obj, patient_database, linked_recorder, gui_callback, reporting);
            obj.AddChild(obj.LinkedSeriesSidePanel, obj.Reporting);
            
            obj.SeriesSidePanel = PTKSeriesSidePanel(obj, patient_database, gui_callback, reporting);
            obj.AddChild(obj.SeriesSidePanel, obj.Reporting);
            
            obj.Repopulate;

            % Add listeners for changes to the loaded series
            obj.AddEventListener(obj.GuiState, 'SeriesUidChangedEvent', @obj.SeriesChanged);            
            obj.AddEventListener(linked_recorder, 'LinkingChanged', @obj.LinkingChanged);            
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKPanel(obj, position, reporting);
        end
        
        function Resize(obj, new_position)
            Resize@PTKPanel(obj, new_position);
            obj.SidePanelAxes.Resize(new_position);
            
            new_position(3) = new_position(3) - 2;
            
            available_height = new_position(4) - 2*obj.SpacingBetweenLists;
            
            panels = {obj.PatientsSidePanel, obj.LinkedSeriesSidePanel, obj.SeriesSidePanel};
            panel_heights = obj.GetPanelHeights(panels, new_position(3), available_height);

            y_offset = max(0, available_height - sum(panel_heights));
            
            series_position = new_position;
            series_position(2) = series_position(2) + y_offset;
            series_position(4) = panel_heights(3);
            
            linked_series_position = new_position;
            linked_series_position(2) = series_position(2) + obj.SpacingBetweenLists + panel_heights(3);
            linked_series_position(4) = panel_heights(2);
            
            patients_position = new_position;
            patients_position(2) = linked_series_position(2) + obj.SpacingBetweenLists + panel_heights(2);
            patients_position(4) = panel_heights(1);
            
            obj.PatientsSidePanel.Resize(patients_position);
            obj.LinkedSeriesSidePanel.Resize(linked_series_position);
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
            obj.LinkedSeriesSidePanel.RepopulateSidePanel(obj.GuiState.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
            obj.SeriesSidePanel.RepopulateSidePanel(obj.GuiState.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
            if obj.ComponentHasBeenCreated
                obj.Resize(obj.Position);
            end
        end
        
    end
    
    methods (Access = private)
        function SeriesChanged(obj, ~, ~)
            % This event fires when the loaded series has been changed.
            
            patient_has_changed = obj.PatientsSidePanel.UpdateSidePanel(obj.GuiState.CurrentPatientId);
            
            % If the patient has changed, we need to repopulate the series list and change
            % the highlighted patient
            if patient_has_changed
                obj.LinkedSeriesSidePanel.RepopulateSidePanel(obj.PatientsSidePanel.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
                obj.SeriesSidePanel.RepopulateSidePanel(obj.PatientsSidePanel.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
                
            else
                % Otherwise, we only need to change the highlighted series
                obj.LinkedSeriesSidePanel.UpdateSidePanel(obj.GuiState.CurrentSeriesUid);                
                obj.SeriesSidePanel.UpdateSidePanel(obj.GuiState.CurrentSeriesUid);                
            end
        end
        
        function LinkingChanged(obj, secondary_uid, ~)
            obj.LinkedSeriesSidePanel.RepopulateSidePanel(obj.PatientsSidePanel.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
            if obj.ComponentHasBeenCreated
                obj.Resize(obj.Position);
            end
        end
        
        
        
    end
    
    methods (Static, Access = private)
        function panel_heights = GetPanelHeights(panels, width, total_height)
            num_panels = numel(panels);
            panel_indices = 1 : num_panels;
            requested_heights = [];
            for panel = panels
                requested_heights(end + 1) = panel{1}.GetRequestedHeight(width);
            end
            panel_heights = zeros(size(requested_heights));
            [sorted_heights, sorted_heights_indices] = sort(requested_heights, 'ascend');
            
            panel_indices = panel_indices(sorted_heights_indices);
            
            height_remaining = total_height;
            for sorted_panel_index = 1 : num_panels
                remaining_panels = num_panels - sorted_panel_index + 1;
                height_divided = height_remaining / remaining_panels;
                if sorted_heights(sorted_panel_index) <= height_divided
                    panel_height = sorted_heights(sorted_panel_index);
                else
                    panel_height = height_divided;
                end
                panel_heights(sorted_heights_indices(sorted_panel_index)) = panel_height;
                height_remaining = height_remaining - sorted_heights(sorted_panel_index);
            end
            
        end        
    end
end