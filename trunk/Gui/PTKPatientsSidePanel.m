classdef PTKPatientsSidePanel < PTKListBoxWithTitle
    % PTKPatientsSidePanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPatientsSidePanel is part of the side panel and contains the sliding list
    %     box showing patient names
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    properties (Access = private)
        PatientDatabase
        GuiCallback
    end
    
    methods
        function obj = PTKPatientsSidePanel(parent, patient_database, gui_callback, reporting)
            obj = obj@PTKListBoxWithTitle(parent, 'PATIENT', 'Import images', 'Delete patient', reporting);
            obj.PatientDatabase = patient_database;
            obj.GuiCallback = gui_callback;
        end
        
        function RepopulateSidePanel(obj, patient_id)
            obj.AddPatientsToListBox(patient_id);
        end
        
        function UpdateSidePanel(obj, patient_id)
            obj.ListBox.SelectItem(patient_id, true);
        end
        
        
        function SelectPatient(obj, patient_id, selected)
            obj.ListBox.SelectItem(patient_id, selected);
        end        
    end
    
    methods (Access = protected)
        
        function AddButtonClicked(obj, tag)
            obj.GuiCallback.ImportMultipleFiles;
        end
        
        function DeleteButtonClicked(obj, tag)
            patient_id = obj.ListBox.SelectedTag;
            if ~isempty(patient_id)
                obj.GuiCallback.DeletePatient(patient_id);
            end
        end
    end
    
    methods (Access = private)
        function AddPatientsToListBox(obj, patient_id)
            [names, ids, short_visible_names] = obj.PatientDatabase.GetListOfPatientNames;
            obj.ListBox.ClearItems;
            
            for index = 1 : numel(ids)
                patient_id = ids{index};
                short_name = short_visible_names{index};
                full_name = names{index};
                patient_item = PTKPatientNameListItem(obj.ListBox.GetListBox, full_name, short_name, patient_id, obj.GuiCallback, obj.Reporting);
                obj.ListBox.AddItem(patient_item);
            end
            
            obj.ListBox.SelectItem(patient_id, true);
        end
    end
end