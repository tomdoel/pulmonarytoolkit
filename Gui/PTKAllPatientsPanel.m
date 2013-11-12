classdef PTKAllPatientsPanel < PTKPanel
    % PTKAllPatientsPanel.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the PUlmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKAllPatientsPanel represents the panel in the Patient Browser
    %     showing all datasets grouped by patient.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        PatientPanels
        PatientDatabase
    end
    
    methods
        function obj = PTKAllPatientsPanel(parent, patient_database, reporting)
            obj = obj@PTKPanel(parent, reporting);
            obj.PatientDatabase = patient_database;
            
            obj.PatientPanels = containers.Map;
            
            obj.AddPatientPanels;
        end
        
        function Resize(obj, new_position)
            obj.ResizePanels(new_position);      
            Resize@PTKPanel(obj, new_position)
        end
        
        function height = GetRequestedHeight(obj)
            height = 0;
            for panel = obj.PatientPanels.values
                height = height + panel{1}.GetRequestedHeight;
            end            
        end
        
        % This determines the y-coordinate (relative to the top of the patient
        % details panel) of the top and bottom of the patient panel
        function [y_min, y_max] = GetYPositionsForPatientId(obj, patient_id)
            y_min = 0;
            y_max = [];
            panels = obj.PatientPanels.values;
            panel_index = 1;
            panel = panels{panel_index};
            while ~strcmp(panel.Id, patient_id)
                panel_index = panel_index + 1;
                if panel_index > length(panels)
                    y_min = [];
                    return;
                end
                
                y_min = y_min + panel.GetRequestedHeight;
                panel = panels{panel_index};
            end
            
            y_max = y_min + panel.GetRequestedHeight;
        end
        
    end
    
    methods (Access = private)
                
        function AddPatientPanels(obj)
            for patient_detail = obj.PatientDatabase.GetPatientInfo
                obj.AddPatientPanel(PTKPatientPanel(obj.PanelHandle, patient_detail{1}, obj.Reporting));
            end
        end
        
        function AddPatientPanel(obj, panel)
            obj.PatientPanels(panel.Id) = panel;
        end
        
        function ResizePanels(obj, new_position)
            panel_width = new_position(3);
            y_coord = 1;
            patient_names = obj.PatientPanels.keys;
            for patient_index = length(patient_names) : -1 : 1
                key = patient_names{patient_index};
                panel = obj.PatientPanels(key);
                panel_size = [1, y_coord, panel_width, panel.GetRequestedHeight];
                panel.Resize(panel_size);
                y_coord = y_coord + panel.GetRequestedHeight;
            end
        end
        
    end
end
