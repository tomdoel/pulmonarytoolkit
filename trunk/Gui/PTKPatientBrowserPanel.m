classdef PTKPatientBrowserPanel < PTKPanel
    % PTKPatientBrowserPanel.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPatientBrowserPanel represents the main panel of the Patient Browser.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (Access = private)
        ListOfPatientsPanel
        AllPatientsSlidingPanel
    end
    
    methods
        function obj = PTKPatientBrowserPanel(parent, patient_database, gui_callback, reporting)
            obj = obj@PTKPanel(parent, reporting);
            obj.AllPatientsSlidingPanel = PTKAllPatientsSlidingPanel(obj, patient_database, gui_callback, reporting);
            obj.ListOfPatientsPanel = PTKListOfPatientsPanel(obj, obj.AllPatientsSlidingPanel, patient_database, reporting);
            obj.AddChild(obj.AllPatientsSlidingPanel);
            obj.AddChild(obj.ListOfPatientsPanel);
        end

        function SelectSeries(obj, patient_id, series_uid, selected)
            obj.ListOfPatientsPanel.SelectPatient(patient_id, selected);
            obj.AllPatientsSlidingPanel.SelectSeries(patient_id, series_uid, selected);
        end
        
        function DatabaseHasChanged(obj)
            obj.ListOfPatientsPanel.DatabaseHasChanged;
            obj.AllPatientsSlidingPanel.DatabaseHasChanged;
        end

        function Resize(obj, position)
            parent_width_pixels = max(1, position(3));
            parent_height_pixels = max(1, position(4));
            panel_position = [1 1 parent_width_pixels parent_height_pixels];
            
            % Resize the panel
            Resize@PTKPanel(obj, panel_position);

            panel_width_pixels = panel_position(3);
            panel_height_pixels = panel_position(4);
            
            % We set the patient list to be a fraction of the panel width, with a
            % maximum cutoff
            max_patient_list_width_pixels = 250;
            if max_patient_list_width_pixels < panel_width_pixels/3
                list_panel_width = max_patient_list_width_pixels;
            else
                list_panel_width = max(1, ceil(panel_width_pixels/3));
            end

            % The patient info panel occupies the rest of the width
            info_panel_width = max(1, panel_width_pixels - list_panel_width);
            
            % Resize the child panels
            obj.ListOfPatientsPanel.Resize([1 1 list_panel_width panel_height_pixels]);
            obj.AllPatientsSlidingPanel.Resize([1+list_panel_width 1 info_panel_width panel_height_pixels]);
            
        end
        
        function input_has_been_processed = Scroll(obj, scroll_count, current_point)
            input_has_been_processed = obj.AllPatientsSlidingPanel.Scroll(scroll_count, current_point);
        end

    end
end