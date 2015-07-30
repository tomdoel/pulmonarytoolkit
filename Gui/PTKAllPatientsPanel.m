classdef PTKAllPatientsPanel < PTKCompositePanel
    % PTKAllPatientsPanel.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKAllPatientsPanel represents the panel in the Patient Browser
    %     showing all datasets grouped by patient.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        PatientPanels
        PatientDatabase
        GuiCallback
        PatientIdMap
    end
    
    methods
        function obj = PTKAllPatientsPanel(parent, patient_database, gui_callback)
            obj = obj@PTKCompositePanel(parent);
            obj.PatientDatabase = patient_database;
            obj.GuiCallback = gui_callback;
            
            obj.PatientPanels = containers.Map;
            
            obj.AddPatientPanels;
        end

        function DatabaseHasChanged(obj)
            obj.RemoveAllPanels;
            obj.PatientPanels = containers.Map;
            obj.AddPatientPanels;
        end
        
        % This determines the y-coordinate (relative to the top of the patient
        % details panel) of the top and bottom of the patient panel
        function [y_min, y_max] = GetYPositionsForPatientId(obj, patient_id)
            if ~obj.PatientIdMap.isKey(patient_id)
                y_min = [];
                y_max = [];
                return;
            end
            
            main_id = obj.PatientIdMap(patient_id);
            panel = obj.PatientPanels(main_id);
            
            y_min = panel.CachedMinY;
            y_max = panel.CachedMaxY;
        end

        function SelectSeries(obj, patient_id, series_uid, selected)
            if obj.PatientIdMap.isKey(patient_id)
                main_id = obj.PatientIdMap(patient_id);
                panel = obj.PatientPanels(main_id);
                panel.SelectSeries(series_uid, selected);
            else
                obj.Reporting.ShowWarning('PTKAllPatientsSlidingPanel.PatientNotFound', 'A patient was selected but the corresponding patient panel was not found', []);
            end
        end
        
        function DeletePatient(obj, patient_id)
            if obj.PatientIdMap.isKey(patient_id)
                main_id = obj.PatientIdMap(patient_id);
                panel = obj.PatientPanels(main_id);
                panel.DeletePatient;
            else
                obj.Reporting.ShowWarning('PTKAllPatientsSlidingPanel.PatientNotFound', 'A patient was selected but the corresponding patient panel was not found', []);
            end
        end
        
        
    end
    
    methods (Access = private)
                
        function AddPatientPanels(obj)
            % The Patient Database will merge together patients with same name if this is specified by the settings
            
            [names, ids, short_visible_names, num_series, num_patients_combined, patient_id_map] = obj.PatientDatabase.GetListOfPatientNamesAndSeriesCount;
            obj.PatientIdMap = patient_id_map;
            
            for index = 1 : numel(ids)
                patient_id = ids{index};
                short_name = short_visible_names{index};
                full_name = names{index};
                series_for_this_patient = num_series(index);
                num_patients = num_patients_combined(index);
                obj.AddPatientPanel(PTKPatientPanel(obj, obj.PatientDatabase, patient_id, full_name, series_for_this_patient, num_patients, obj.GuiCallback));
            end
        end
        
        function AddPatientPanel(obj, panel)
            obj.PatientPanels(panel.Id) = panel;
            obj.AddPanel(panel);
        end
        
    end
end
