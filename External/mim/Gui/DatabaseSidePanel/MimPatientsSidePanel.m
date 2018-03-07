classdef MimPatientsSidePanel < GemListBoxWithTitle
    % MimPatientsSidePanel. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimPatientsSidePanel is part of the side panel and contains the sliding list
    %     box showing patient names
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    
    properties (Access = private)
        PatientDatabase
        GuiCallback
        PatientIdMap
        GroupPatientsWithSameName
    end
    
    properties (SetAccess = private)    
        CurrentPatientId
    end
    
    methods
        function obj = MimPatientsSidePanel(parent, patient_database, group_patients_with_same_name, gui_callback)
            obj = obj@GemListBoxWithTitle(parent, 'PATIENT', 'Import images', 'Delete patient');
            obj.PatientDatabase = patient_database;
            obj.GuiCallback = gui_callback;
            obj.GroupPatientsWithSameName = group_patients_with_same_name;
        end
        
        function RepopulateSidePanel(obj, patient_id)
            obj.AddPatientsToListBox(patient_id);
        end
        
        function patient_has_changed = UpdateSidePanel(obj, patient_id)
            mapped_patient_id = obj.GetMappedPatientId(patient_id);
            patient_has_changed = ~strcmp(mapped_patient_id, obj.CurrentPatientId);
            if patient_has_changed
                obj.ListBox.SelectItem(mapped_patient_id, true);
            end
            obj.CurrentPatientId = mapped_patient_id;
        end
        
        function SelectPatient(obj, patient_id, selected)
            mapped_patient_id = obj.GetMappedPatientId(patient_id);
            obj.ListBox.SelectItem(mapped_patient_id, selected);
        end
        
        function SelectNextPatient(obj)
            next_patient_id = obj.ListBox.GetNextItemId;
            if ~isempty(next_patient_id)
                obj.GuiCallback.PatientClicked(next_patient_id);
            end
        end
        
        function SelectPreviousPatient(obj)
            prev_patient_id = obj.ListBox.GetPreviousItemId;
            if ~isempty(prev_patient_id)
                obj.GuiCallback.PatientClicked(prev_patient_id);
            end
        end
    end
    
    methods (Access = protected)
        
        function AddButtonClicked(obj, ~, event_data)
            obj.GuiCallback.AddPatient;
        end
        
        function DeleteButtonClicked(obj, ~, event_data)
            patient_id = obj.ListBox.GetListBox.SelectedTag;
            if ~isempty(patient_id)
                obj.GuiCallback.DeletePatient(patient_id);
            end
        end
    end
    
    methods (Access = private)
        function mapped_patient_id = GetMappedPatientId(obj, patient_id)
            if isempty(patient_id) || ~obj.PatientIdMap.isKey(patient_id)
                mapped_patient_id = [];
            else
                mapped_patient_id = obj.PatientIdMap(patient_id);
            end
        end
            
        function AddPatientsToListBox(obj, selected_patient_id)
            [names, ids, short_visible_names, patient_id_map] = obj.PatientDatabase.GetListOfPatientNames(obj.GuiCallback.GetCurrentProject, obj.GroupPatientsWithSameName);
            obj.PatientIdMap = patient_id_map;
            obj.ListBox.ClearItems;
            
            for index = 1 : numel(ids)
                patient_id = ids{index};
                short_name = short_visible_names{index};
                full_name = names{index};
                patient_item = MimPatientNameListItem(obj.ListBox.GetListBox, full_name, short_name, patient_id, obj.GuiCallback);
                obj.ListBox.AddItem(patient_item);
            end
            
            obj.ListBox.SelectItem(selected_patient_id, true);
        end
    end
end