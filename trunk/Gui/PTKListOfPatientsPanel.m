classdef PTKListOfPatientsPanel < PTKPanel
    % PTKListOfPatientsPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the PUlmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKListOfPatientsPanel represents a panel showing the list of patients in
    %     the Patient Browser.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (Access = private)
        PatientDatabase
        PatientListBox
        AllPatientsPanel
        
        PatientIds
    end
    
    properties (Constant, Access = private)
        ControlPanelHeight = 40
        FontSize = 30
    end
    
    methods
        function obj = PTKListOfPatientsPanel(parent, all_patients_panel, patient_database, reporting)
            obj = obj@PTKPanel(parent, reporting);
            obj.PatientDatabase = patient_database;
            obj.AllPatientsPanel = all_patients_panel;

            obj.PatientListBox = uicontrol('Parent', obj.PanelHandle, 'Style', 'listbox', ...
                'Units', 'pixels', 'Position', [1 1 200 200], 'Callback', @obj.ListBoxCallBack, ...
                'String', 'No Patients', 'FontSize', obj.FontSize, 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'ForegroundColor', 'white');
            
            obj.AddPatientsToListBox;
        end
        
        function Resize(obj, panel_position)            
            panel_width = panel_position(3);
            panel_height = panel_position(4);
            list_box_height = max(1, panel_height - obj.ControlPanelHeight);
            set(obj.PatientListBox, 'Position', [1 1, panel_width, list_box_height]);
            
            Resize@PTKPanel(obj, panel_position);
        end
        
    end
    
    methods (Access = private)
        
        function AddPatientsToListBox(obj)
            [names, ids] = obj.PatientDatabase.GetListOfPatientNames;
            set(obj.PatientListBox, 'String', names);
            obj.PatientIds = ids;
        end
        
        function ListBoxCallBack(obj, hObject, ~, ~)
            index_selected = get(hObject, 'Value');
            patient_id = obj.PatientIds{index_selected};
            obj.AllPatientsPanel.SelectPatient(patient_id);
        end
        
    end
end