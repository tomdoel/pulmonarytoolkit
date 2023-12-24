classdef MimPatientBrowserAllPatientsSlidingPanel < GemSlidingPanel
    % MimPatientBrowserAllPatientsSlidingPanel. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimPatientBrowserAllPatientsSlidingPanel represents the panel underneath the
    %     MimPatientBrowserAllPatientsPanel, which allows the panel to be scrolled using a
    %     scrollbar and swipe gestures.
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    methods
        function obj = MimPatientBrowserAllPatientsSlidingPanel(parent, patient_database, group_patients_with_same_name, gui_callback)
            obj = obj@GemSlidingPanel(parent);
            obj.FloatingPanel = MimPatientBrowserAllPatientsPanel(obj, patient_database, group_patients_with_same_name, gui_callback);
            obj.AddChild(obj.FloatingPanel);
        end
        
        function SelectSeries(obj, patient_id, series_uid, selected)
            obj.SelectPatient(patient_id);
            obj.FloatingPanel.SelectSeries(patient_id, series_uid, selected);
        end
        
        function SelectPatient(obj, patient_id)
            
            % Get the y-coordinates of the panel corresponding to this patient
            [y_min, y_max] = obj.FloatingPanel.GetYPositionsForPatientId(patient_id);
            if isempty(y_min)
                % There might be a reason the patient is not found, so
                % don't report the warning
%                 obj.Reporting.ShowWarning('MimPatientBrowserAllPatientsSlidingPanel.PatientNotFound', 'A patient was selected but the corresponding patient panel was not found', []);
                return;
            end

            obj.ScrollPanelToThisYPosition(y_min);
            
        end
        
        function DeletePatient(obj, patient_id)
            obj.FloatingPanel.DeletePatient(patient_id);
        end

        function DatabaseHasChanged(obj)
            obj.FloatingPanel.DatabaseHasChanged;
        end
        
    end
end