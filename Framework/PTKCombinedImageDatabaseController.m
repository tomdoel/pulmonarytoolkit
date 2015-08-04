classdef PTKCombinedImageDatabaseController < CoreBaseClass
    % PTKCombinedImageDatabaseController. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    events
        ProjectChangedEvent
        PatientChangedEvent
    end
   
    properties (Access = private)
        GuiCallback
        CurrentProject = PTKImageDatabase.LocalDatabaseId;
        MatNatDatabase
    end

    methods
        function obj = PTKCombinedImageDatabaseController(gui_callback, matnat_database)
            obj.MatNatDatabase = matnat_database;
            obj.GuiCallback = gui_callback;
        end
        
        function ProjectClicked(obj, project_id)
            obj.CurrentProject = project_id;
            notify(obj, 'ProjectChangedEvent', PTKEventData(project_id));
        end
        
        function PatientClicked(obj, patient_id)
            if strcmp(obj.CurrentProject, PTKImageDatabase.LocalDatabaseId)
                obj.GuiCallback.LoadPatient(patient_id);
            else
                notify(obj, 'PatientChangedEvent', PTKEventData(patient_id));
            end
        end
        
        function SeriesClicked(obj, patient_id, series_uid)
            if strcmp(obj.CurrentProject, PTKImageDatabase.LocalDatabaseId)
                obj.GuiCallback.LoadFromPatientBrowser(series_uid);
            else
                if ~isempty(obj.MatNatDatabase)
                    import_path = obj.MatNatDatabase.downloadScan(obj.CurrentProject, patient_id, series_uid);
                    obj.GuiCallback.ImportFromPath(import_path);
                end
            end
        end
        
        function AddPatient(obj)
            obj.GuiCallback.ImportMultipleFiles;
        end
        
        function AddSeries(obj)
            obj.GuiCallback.ImportMultipleFiles;
        end
        
        function DeletePatient(obj, patient_id)
            obj.GuiCallback.DeletePatient(patient_id);
        end
        
        function DeleteSeries(obj, series_uid)
            obj.GuiCallback.DeleteDataset(series_uid);
        end
        
        function RefreshProjects(obj)
        end

        function BringToFront(obj)
            obj.GuiCallback.BringToFront;
        end
        
        function UnlinkDataset(obj, series_uid)
            obj.GuiCallback.UnlinkDataset(series_uid);
        end
        
        function project_id = GetCurrentProject(obj)
            project_id = obj.CurrentProject;
        end
    end    
end