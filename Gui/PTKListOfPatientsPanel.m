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
        AddButton
        DeleteButton
        AllPatientsPanel
        
        GuiCallback
        PatientIds
        LockSetPatient
        LastSelectedPatientId
    end
    
    properties (Constant, Access = private)
        ControlPanelHeight = 40
        ButtonSize = 32
        ButtonSpacing = 4
        FontSize = 30
        PatientText = 'Patient'
        PatientTextFontSize = 30;
    end
    
    methods
        function obj = PTKListOfPatientsPanel(parent, all_patients_panel, patient_database, gui_callback, reporting)
            obj = obj@PTKPanel(parent, reporting);
            obj.LockSetPatient = false;
            obj.PatientDatabase = patient_database;
            obj.AllPatientsPanel = all_patients_panel;
            obj.GuiCallback = gui_callback;
            obj.AddButton = PTKButton(obj, '+', 'Import images', 'Add', @obj.AddButtonClicked);
            obj.AddButton.FontSize = obj.PatientTextFontSize;
            obj.AddButton.BackgroundColour = PTKSoftwareInfo.BackgroundColour;
            obj.AddChild(obj.AddButton, obj.Reporting);
            obj.DeleteButton = PTKButton(obj, '-', 'Delete this patient', 'Delete', @obj.DeleteButtonClicked);
            obj.DeleteButton.BackgroundColour = PTKSoftwareInfo.BackgroundColour;
            obj.DeleteButton.FontSize = obj.PatientTextFontSize;
            obj.AddChild(obj.DeleteButton, obj.Reporting);
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
                patient_index = find(ismember(obj.PatientIds, obj.LastSelectedPatientId), 1);
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
            patient_text_position = [1 list_box_height, panel_position(3) - 2*obj.ButtonSize - obj.ButtonSpacing, obj.ControlPanelHeight];
            set(obj.PatientTextControl, 'Position', patient_text_position);
            set(obj.PatientListBox, 'Position', [1 1, panel_width, list_box_height]);
            
            
            delete_button_position = [panel_position(3)-2*obj.ButtonSize - obj.ButtonSpacing, list_box_height + obj.ButtonSpacing, obj.ButtonSize, obj.ButtonSize];
            add_button_position = [panel_position(3)-obj.ButtonSize, list_box_height + obj.ButtonSpacing, obj.ButtonSize, obj.ButtonSize];
            
            obj.AddButton.Resize(add_button_position);
            obj.DeleteButton.Resize(delete_button_position);
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
                    patient_index = find(ismember(obj.PatientIds, patient_id), 1);
                else
                    patient_index = [];
                end
                obj.LockSetPatient = true;
                set(obj.PatientListBox, 'Value', patient_index);
                obj.LockSetPatient = false;
            end
        end
        
        function AddButtonClicked(obj, tag)
            obj.GuiCallback.AddData;
        end
        
        function DeleteButtonClicked(obj, tag)
            index_selected = get(obj.PatientListBox, 'Value');
            if ~isempty(index_selected)
                patient_id = obj.PatientIds{index_selected};
                obj.AllPatientsPanel.DeletePatient(patient_id);
            end
        end
    end

    methods (Access = private)
        
        function AddPatientsToListBox(obj)
            [names, ids, short_visible_names, patient_id_map] = obj.PatientDatabase.GetListOfPatientNames;
            current_index_selected = get(obj.PatientListBox, 'Value');
            if isempty(obj.PatientIds) || isempty(current_index_selected)
                new_index = [];
            else
                current_patient_id = obj.PatientIds{current_index_selected};
                new_index = find(strcmp(ids, current_patient_id), 1, 'first');
            end
            
            if isempty(ids)
                new_index = [];
            else
                if isempty(new_index)
                    if numel(ids) > numel(obj.PatientIds)
                        new_index = 1;
                    else
                        new_index = numel(ids);
                    end
                end
            end
            
            set(obj.PatientListBox, 'String', short_visible_names, 'Value', new_index);
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