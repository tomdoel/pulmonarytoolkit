classdef MimSidePanel < GemPanel
    % MimSidePanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     MimSidePanel represents the panel showing patients and series at the
    %     left side of the PTK GUI.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        ProjectsSidePanel
        PatientsSidePanel
        ProtocolSidePanel
        SeriesSidePanel
        LinkedSeriesSidePanel
        PatientInfoSidePanel
        PatientNameTextControl
        SeriesDescriptions
        Controller
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
        function obj = MimSidePanel(parent, controller, patient_database, state, linked_recorder)
            obj = obj@GemPanel(parent);
            
            obj.RightBorder = true;
            
            obj.Controller = controller;
            obj.GuiState = state;
            
            obj.ProjectsSidePanel = PTKProjectsSidePanel(obj, patient_database, controller);
            obj.AddChild(obj.ProjectsSidePanel);
            
            obj.PatientsSidePanel = PTKPatientsSidePanel(obj, patient_database, controller);
            obj.AddChild(obj.PatientsSidePanel);
            
            obj.LinkedSeriesSidePanel = PTKLinkedSeriesSidePanel(obj, patient_database, linked_recorder, controller);
            obj.AddChild(obj.LinkedSeriesSidePanel);
            
            obj.SeriesSidePanel = PTKSeriesSidePanel(obj, patient_database, controller);
            obj.AddChild(obj.SeriesSidePanel);
            
            obj.Repopulate;

            % Add listeners for changes to the loaded series
            obj.AddEventListener(controller, 'ProjectChangedEvent', @obj.ProjectChanged);            
            obj.AddEventListener(controller, 'PatientChangedEvent', @obj.PatientChanged);            
            obj.AddEventListener(state, 'SeriesUidChangedEvent', @obj.SeriesChanged);            
            obj.AddEventListener(state, 'PatientIdChangedEvent', @obj.PatientChanged);
            obj.AddEventListener(linked_recorder, 'LinkingChanged', @obj.LinkingChanged);            
            obj.AddEventListener(patient_database, 'DatabaseHasChanged', @obj.DatabaseHasChanged);
        end
        
        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemPanel(obj, position);
        end
        
        function Resize(obj, new_position)
            Resize@GemPanel(obj, new_position);
            
            % After calling Resize@GemPanel, the position will have been adjusted due to the border
            new_position = obj.InnerPosition;
            
            % Only show the projects panel if there is more than one
            % project
            if obj.ProjectsSidePanel.GetNumItems < 2
                obj.ProjectsSidePanel.Disable;
                panels = {};
            else
                obj.ProjectsSidePanel.Enable;
                panels = {obj.ProjectsSidePanel};
            end

            % Only show the linked series panel if there is at least one
            % linked series
            if obj.LinkedSeriesSidePanel.GetNumItems < 1
                obj.LinkedSeriesSidePanel.Disable;
                panels = [panels, {obj.PatientsSidePanel, obj.SeriesSidePanel}];
            else
                obj.LinkedSeriesSidePanel.Enable;
                panels = [panels, {obj.PatientsSidePanel, obj.LinkedSeriesSidePanel, obj.SeriesSidePanel}];
            end
            
            available_height = new_position(4) - (numel(panels) - 1)*obj.SpacingBetweenLists;
            
            panel_heights = obj.GetPanelHeights(panels, new_position(3), available_height);

            y_offset = max(0, available_height - sum(panel_heights));
            y_position = new_position(2) + y_offset;
            
            for panel_index = numel(panels) : -1 : 1
                panel = panels{panel_index};
                panel_position = new_position;
                panel_position(2) = y_position;
                panel_position(4) = panel_heights(panel_index);
                panel.Resize(panel_position);
                y_position = y_position + obj.SpacingBetweenLists + panel_heights(panel_index);
            end
        end
        
        
        function height = GetRequestedHeight(obj, width)
            height = obj.PanelHeight;
        end
        
        function Repopulate(obj)
            obj.ProjectsSidePanel.RepopulateSidePanel(obj.Controller.GetCurrentProject);
            obj.PatientsSidePanel.RepopulateSidePanel(obj.GuiState.CurrentPatientId);
            obj.LinkedSeriesSidePanel.RepopulateSidePanel(obj.GuiState.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
            obj.SeriesSidePanel.RepopulateSidePanel(obj.GuiState.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
            if obj.ComponentHasBeenCreated
                obj.Resize(obj.Position);
            end
        end

        function Refresh(obj, ~, ~)
            obj.Repopulate;
        end
        
        function input_has_been_processed = ShortcutKeys(obj, key)
            % Process shortcut keys for the side panel.
            if strcmpi(key, 'end')
                obj.PatientsSidePanel.SelectNextPatient;
                input_has_been_processed = true;
            elseif strcmpi(key, 'home')
                obj.PatientsSidePanel.SelectPreviousPatient;
                input_has_been_processed = true;
            elseif strcmpi(key, 'pageup')
                obj.SeriesSidePanel.SelectPreviousSeries;
                input_has_been_processed = true;
            elseif strcmpi(key, 'pagedown')
                obj.SeriesSidePanel.SelectNextSeries;
                input_has_been_processed = true;
            elseif strcmpi(key, 'delete')
                obj.SeriesSidePanel.DeleteSelectedSeries;
                input_has_been_processed = true;
            elseif strcmpi(key, 'insert')
                obj.Controller.AddSeries;
                input_has_been_processed = true;
            else
                input_has_been_processed = false;
            end
        end        
    end
    
    methods (Access = private)
        function DatabaseHasChanged(obj, ~, ~)
            obj.Repopulate;
        end
        
        function ProjectChanged(obj, ~, event_data)
            project_id = event_data.Data;
            project_has_changed = obj.ProjectsSidePanel.UpdateSidePanel(project_id);
            
            if project_has_changed
                obj.PatientsSidePanel.RepopulateSidePanel(obj.GuiState.CurrentPatientId);
                obj.LinkedSeriesSidePanel.RepopulateSidePanel(obj.PatientsSidePanel.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
                obj.SeriesSidePanel.RepopulateSidePanel(obj.PatientsSidePanel.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
                if ~isempty(obj.Position)
                    obj.Resize(obj.Position);
                end
            end
        end
        
        function PatientChanged(obj, ~, event_data)
            patient_id = event_data.Data;
            patient_has_changed = obj.PatientsSidePanel.UpdateSidePanel(patient_id);
            
            if patient_has_changed
                obj.LinkedSeriesSidePanel.RepopulateSidePanel(patient_id, obj.GuiState.CurrentSeriesUid);
                obj.SeriesSidePanel.RepopulateSidePanel(patient_id, obj.GuiState.CurrentSeriesUid);
                if ~isempty(obj.Position)
                    obj.Resize(obj.Position);
                end
            end
        end
        
        function SeriesChanged(obj, ~, ~)
            % This event fires when the loaded series has been changed.
            
            patient_has_changed = obj.PatientsSidePanel.UpdateSidePanel(obj.GuiState.CurrentPatientId);
            
            % If the patient has changed, we need to repopulate the series list and change
            % the highlighted patient
            if patient_has_changed
                obj.LinkedSeriesSidePanel.RepopulateSidePanel(obj.PatientsSidePanel.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
                obj.SeriesSidePanel.RepopulateSidePanel(obj.PatientsSidePanel.CurrentPatientId, obj.GuiState.CurrentSeriesUid);
                if ~isempty(obj.Position)
                    obj.Resize(obj.Position);
                end
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
            requested_heights = [];
            for panel = panels
                requested_heights(end + 1) = panel{1}.GetRequestedHeight(width);
            end
            panel_heights = zeros(size(requested_heights));
            [sorted_heights, sorted_heights_indices] = sort(requested_heights, 'ascend');
            
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
                height_remaining = height_remaining - panel_height;
            end
            
        end        
    end
end