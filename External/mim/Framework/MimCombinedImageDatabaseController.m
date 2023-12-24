classdef MimCombinedImageDatabaseController < CoreBaseClass
    % MimCombinedImageDatabaseController
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    events
        ProjectChangedEvent
        PatientChangedEvent
    end
   
    properties (Access = private)
        GuiCallback
        CurrentProject = MimImageDatabase.LocalDatabaseId;
        MatNatDatabase
    end

    methods
        function obj = MimCombinedImageDatabaseController(gui_callback, matnat_database)
            obj.MatNatDatabase = matnat_database;
            obj.GuiCallback = gui_callback;
        end
        
        function ProjectClicked(obj, project_id)
            obj.CurrentProject = project_id;
            notify(obj, 'ProjectChangedEvent', CoreEventData(project_id));
        end
        
        function PatientClicked(obj, patient_id)
            if strcmp(obj.CurrentProject, MimImageDatabase.LocalDatabaseId)
                obj.GuiCallback.LoadPatient(patient_id);
            else
                notify(obj, 'PatientChangedEvent', CoreEventData(patient_id));
            end
        end
        
        function SeriesClicked(obj, patient_id, series_uid)
            if strcmp(obj.CurrentProject, MimImageDatabase.LocalDatabaseId)
                obj.GuiCallback.LoadFromPatientBrowser(series_uid, patient_id);
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