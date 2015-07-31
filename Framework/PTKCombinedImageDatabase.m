classdef PTKCombinedImageDatabase < PTKBaseClass
    % PTKCombinedImageDatabase. Part of the internal framework of the Pulmonary Toolkit.
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
    
    properties (Access = private)
        ImageDatabase
        MatNatDatabase
    end
    
    events
        DatabaseHasChanged
    end
    
    methods
        function obj = PTKCombinedImageDatabase(image_database, matnat_database)
            obj.ImageDatabase = image_database;
            obj.MatNatDatabase = matnat_database;
            
            obj.AddEventListener(image_database, 'DatabaseHasChanged', @obj.ImageDatabaseChanged);
        end
        
        function [project_names, project_ids] = GetListOfProjects(obj)
            [project_names_1, project_ids_1] = obj.ImageDatabase.GetListOfProjects;
            [project_names_2, project_ids_2] = obj.MatNatDatabase.GetListOfProjects;
            project_names = [project_names_1, project_names_2];
            project_ids = [project_ids_1, project_ids_2];
        end
        
        function datasets = GetAllSeriesForThisPatient(obj, project_id, patient_id)
            datasets_1 = obj.ImageDatabase.GetAllSeriesForThisPatient(project_id, patient_id);
            datasets_2 = obj.MatNatDatabase.GetAllSeriesForThisPatient(project_id, patient_id);
            datasets = horzcat(datasets_1, datasets_2);
        end
        
        function [names, ids, short_visible_names, patient_id_map] = GetListOfPatientNames(obj, project_id)
            
            [names1, ids1, short_visible_names1, patient_id_map1] = obj.ImageDatabase.GetListOfPatientNames(project_id);
            [names2, ids2, short_visible_names2, patient_id_map2] = obj.MatNatDatabase.GetListOfPatientNames(project_id);
            
            names = horzcat(names1, names2);
            ids = horzcat(ids1, ids2);
            short_visible_names = horzcat(short_visible_names1, short_visible_names2);
            
            patient_id_map = patient_id_map1;
            
            for key = patient_id_map2.keys
                patient_id_map(key{1}) = patient_id_map2(key{1});
            end
        end
        
        
        function [names, ids, short_visible_names, num_series, num_patients_combined, patient_id_map] = GetListOfPatientNamesAndSeriesCount(obj, project_id)
   
            [names1, ids1, short_visible_names1, num_series_1, num_patients_combined_1, patient_id_map1] = obj.ImageDatabase.GetListOfPatientNamesAndSeriesCount(project_id);
            [names2, ids2, short_visible_names2, num_series_2, num_patients_combined_2, patient_id_map2] = obj.MatNatDatabase.GetListOfPatientNamesAndSeriesCount(project_id);
            
            names = horzcat(names1, names2);
            ids = horzcat(ids1, ids2);
            short_visible_names = horzcat(short_visible_names1, short_visible_names2);
            num_series = num_series_1 + num_series_2;
            num_patients_combined = num_patients_combined_1 + num_patients_combined_2;
            
            patient_id_map = patient_id_map1;
            
            for key = patient_id_map2.keys
                patient_id_map(key) = patient_id_map2(key);
            end
        end
    end
    
    methods (Access = private)
        function ImageDatabaseChanged(obj, ~, ~)
            notify(obj, 'DatabaseHasChanged');
        end
    end    
end