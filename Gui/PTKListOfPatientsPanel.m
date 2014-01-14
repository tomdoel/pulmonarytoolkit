classdef PTKListOfPatientsPanel < PTKPanel
    % PTKListOfPatientsPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
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
        PatientTextControl
        AllPatientsPanel
        
        PatientIds
        LockSetPatient
        LastSelectedPatientId
    end
    
    properties (Constant, Access = private)
        ControlPanelHeight = 40
        FontSize = 30
        PatientText = 'Patient'
        PatientTextFontSize = 30;
    end
    
    methods
        function obj = PTKListOfPatientsPanel(parent, all_patients_panel, patient_database, reporting)
            obj = obj@PTKPanel(parent, reporting);
            obj.LockSetPatient = false;
            obj.PatientDatabase = patient_database;
            obj.AllPatientsPanel = all_patients_panel;
        end
        
        function delete(obj)
            delete(obj.PatientListBox);
            delete(obj.PatientTextControl);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            list_box_height = max(1, position(4) - obj.ControlPanelHeight);
            patient_text_position = [1 list_box_height, position(3), obj.ControlPanelHeight];
            obj.PatientTextControl = uicontrol('Style', 'text', 'Parent', obj.Parent.GetContainerHandle(reporting), 'Units', 'pixels', 'FontSize', obj.PatientTextFontSize, 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'ForegroundColor', 'white', 'HorizontalAlignment', 'left', 'String', obj.PatientText, 'Position', patient_text_position);            
            list_box_position = [1 1, position(3), list_box_height];
            obj.PatientListBox = uicontrol('Parent', obj.Parent.GetContainerHandle(reporting), 'Style', 'listbox', ...
                'Units', 'pixels', 'Position', list_box_position, 'Callback', @obj.ListBoxCallBack, ...
                'String', 'No Patients', 'FontSize', obj.FontSize, 'Min', 0, 'Max', 2, ...
                'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'ForegroundColor', 'white');
            obj.AddPatientsToListBox;

            if isempty(obj.LastSelectedPatientId);
                patient_index = [];
            else
                patient_index = find(ismember(obj.PatientIds, obj.LastSelectedPatientId));
            end
            obj.LockSetPatient = true;
            set(obj.PatientListBox, 'Value', patient_index);
            obj.LockSetPatient = false;
        end
        
        function Resize(obj, panel_position)
            Resize@PTKPanel(obj, panel_position);
            panel_width = panel_position(3);
            panel_height = panel_position(4);
            list_box_height = max(1, panel_height - obj.ControlPanelHeight);
            patient_text_position = [1 list_box_height, panel_position(3), obj.ControlPanelHeight];
            set(obj.PatientTextControl, 'Position', patient_text_position);
            set(obj.PatientListBox, 'Position', [1 1, panel_width, list_box_height]);
        end
        
        function DatabaseHasChanged(obj)
            obj.AddPatientsToListBox;
        end
        
        function SelectPatient(obj, patient_id, selected)
            if selected
                obj.LastSelectedPatientId = patient_id;
            else
                obj.LastSelectedPatientId = [];
            end
            
            if obj.ComponentHasBeenCreated
                if selected
                    patient_index = find(ismember(obj.PatientIds, patient_id));
                else
                    patient_index = [];
                end
                obj.LockSetPatient = true;
                set(obj.PatientListBox, 'Value', patient_index);
                obj.LockSetPatient = false;
            end
        end
        
    end
    
    methods (Access = private)
        
        function AddPatientsToListBox(obj)
            [names, ids, short_visible_names] = obj.PatientDatabase.GetListOfPatientNames;
            set(obj.PatientListBox, 'String', short_visible_names);
            obj.PatientIds = ids;
        end
        
        function ListBoxCallBack(obj, hObject, ~, ~)
            if ~obj.LockSetPatient 
                index_selected = get(hObject, 'Value');
                if ~isempty(index_selected)
                    patient_id = obj.PatientIds{index_selected};
                    obj.AllPatientsPanel.SelectPatient(patient_id);
                end
            end
        end
        
    end
end