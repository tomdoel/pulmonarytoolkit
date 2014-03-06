classdef PTKAllPatientsSlidingPanel < PTKSlidingPanel
    % PTKAllPatientsSlidingPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKAllPatientsSlidingPanel represents the panel underneath the
    %     PTKAllPatientsPanel, which allows the panel to be scrolled using a
    %     scrollbar and swipe gestures.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods
        function obj = PTKAllPatientsSlidingPanel(parent, patient_database, gui_callback, reporting)
            obj = obj@PTKSlidingPanel(parent, reporting);
            obj.FloatingPanel = PTKAllPatientsPanel(obj, patient_database, gui_callback, reporting);
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
                obj.Reporting.ShowWarning('PTKAllPatientsSlidingPanel.PatientNotFound', 'A patient was selected but the corresponding patient panel was not found', []);
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