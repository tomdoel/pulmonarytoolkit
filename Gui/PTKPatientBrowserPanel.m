classdef PTKPatientBrowserPanel < PTKPanel
    % PTKPatientBrowserPanel.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the PUlmonary Toolkit to help
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
        function obj = PTKPatientBrowserPanel(parent, patient_database, reporting)
            obj = obj@PTKPanel(parent, reporting);
            obj.AllPatientsSlidingPanel = PTKAllPatientsSlidingPanel(obj.PanelHandle, patient_database, reporting);
            obj.ListOfPatientsPanel = PTKListOfPatientsPanel(obj.PanelHandle, obj.AllPatientsSlidingPanel, patient_database, reporting);
        end
        
        function delete(obj)
            delete(obj.ListOfPatientsPanel);
            delete(obj.AllPatientsSlidingPanel);
        end
        
        function Resize(obj, parent_position)
            parent_width_pixels = max(1, parent_position(3));
            parent_height_pixels = max(1, parent_position(4));
            panel_position = [1 1 parent_width_pixels parent_height_pixels];

            panel_width_pixels = panel_position(3);
            panel_height_pixels = panel_position(4);
            
            % We set the patient list to be a fraction of the panel width, with a
            % maximum cutoff
            max_patient_list_width_pixels = 200;
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
            
            % Resize the parent panel
            Resize@PTKPanel(obj, panel_position);
        end
        
        function input_has_been_processed = Scroll(obj, scroll_count, current_point)
            input_has_been_processed = obj.AllPatientsSlidingPanel.Scroll(scroll_count, current_point);
        end

    end
end