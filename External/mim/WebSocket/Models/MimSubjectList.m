classdef MimSubjectList < MimModel
    methods (Access = protected)
        function value = run(obj)
            database = obj.Callback.getMim().GetImageDatabase();
            [projectNames, projectIds] = database.GetListOfProjects();
            subjectList = {};
            for projectIndex = 1 : numel(projectNames)
                projectName = projectNames{projectIndex};
                projectId = projectIds{projectIndex};
                [names, ids, short_visible_names, num_series, num_patients_combined, patient_id_map] = database.GetListOfPatientNamesAndSeriesCount(projectId, true);
                for nameIndex = 1 : numel(names)
                    subjectId = ids{nameIndex};
                    name = names{nameIndex};
                    parameters = {};
                    parameters.subjectId = subjectId;
                    parameters.projectName = projectName;
                    parameters.projectId = projectId;
                    parameters.subjectName = name;
                    
                    modelId = obj.Callback.buildModelId('MimWSSubject', parameters);
                    subjectList{end + 1} = MimSubjectList.SubjectListEntry(modelId, name, subjectId, projectName, [], []);
                    
                end
            end
            value = subjectList;
        end
    end
    
    methods (Static, Access = private)
        function subjectListEntry = SubjectListEntry(modelId, label, id, project, uri, insert_date)
            subjectListEntry = struct();
            subjectListEntry.modelId = modelId;
            subjectListEntry.label = label;
            subjectListEntry.ID = id;
            subjectListEntry.project = project;
            subjectListEntry.URI = uri;
            subjectListEntry.insert_date = insert_date;
        end        
    end
end