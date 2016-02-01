classdef PTKProjectsSidePanel < GemListBoxWithTitle
    % PTKProjectsSidePanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKProjectsSidePanel is part of the side panel and contains the sliding list
    %     box showing project names
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    properties (Access = private)
        PatientDatabase
        GuiCallback
    end
    
    properties (SetAccess = private)    
        CurrentProjectId
    end
    
    methods
        function obj = PTKProjectsSidePanel(parent, patient_database, gui_callback)
            obj = obj@GemListBoxWithTitle(parent, 'PROJECT', 'Import images', 'Delete project');
            obj.PatientDatabase = patient_database;
            obj.GuiCallback = gui_callback;
        end
        
        function RepopulateSidePanel(obj, project_id)
            obj.AddProjectsToListBox(project_id);
        end
        
        function project_has_changed = UpdateSidePanel(obj, project_id)
            project_has_changed = ~strcmp(project_id, obj.CurrentProjectId);
            if project_has_changed
                obj.ListBox.SelectItem(project_id, true);
            end
            obj.CurrentProjectId = project_id;
        end

        function SelectProject(obj, project_id, selected)
            obj.ListBox.SelectItem(project_id, selected);
        end
        
    end
    
    methods (Access = protected)
        
        function AddButtonClicked(obj, ~, event_data)
        end
        
        function DeleteButtonClicked(obj, ~, event_data)
        end
    end
    
    methods (Access = private)            
        function AddProjectsToListBox(obj, selected_project_id)
            [project_names, project_ids] = obj.PatientDatabase.GetListOfProjects;
            obj.ListBox.ClearItems;
            
            for index = 1 : numel(project_ids)
                project_name = project_names{index};
                project_id = project_ids{index};
                patient_item = PTKProjectNameListItem(obj.ListBox.GetListBox, project_name, project_id, obj.GuiCallback);
                obj.ListBox.AddItem(patient_item);
            end
            
            obj.ListBox.SelectItem(selected_project_id, true);
        end
    end
end