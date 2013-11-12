classdef PTKAllPatientsSlidingPanel < PTKSlidingPanel
    % PTKAllPatientsSlidingPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the PUlmonary Toolkit to help
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
        function obj = PTKAllPatientsSlidingPanel(parent, patient_database, reporting)
            obj = obj@PTKSlidingPanel(parent, reporting);
            obj.FloatingPanel = PTKAllPatientsPanel(obj.PanelHandle, patient_database, reporting);
            obj.Update;
        end
        
        function SelectPatient(obj, patient_id)
            
            % Get the y-coordinates of the panel corresponding to this patient
            [y_min, y_max] = obj.FloatingPanel.GetYPositionsForPatientId(patient_id);
            if isempty(y_min)
                obj.Reporting.ShowWarning('PTKAllPatientsSlidingPanel.PatientNotFound', 'A patient was selected but the corresponding patient panel was not found', []);
                return;
            end
            
            fixed_panel_position = get(obj.PanelHandle, 'Position');
            fixed_panel_height = fixed_panel_position(4);
            patient_panel_height = y_max - y_min;
            
            % If the patient panel height is greater than the height of the
            % whole panel, then we scroll so that the patient panel is aligned
            % at the top
            if patient_panel_height >= fixed_panel_height
                obj.ScrollPanelToThisYPosition(y_min, fixed_panel_position);
                
            % Otherwise, we scroll so that the patient panel is centred
            else
                offset = floor((fixed_panel_height - patient_panel_height)/2);
                obj.ScrollPanelToThisYPosition(max(0, y_min - offset), fixed_panel_position);
            end
            
        end
    end
end