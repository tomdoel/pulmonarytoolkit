classdef MimSubjectList < MimWSModel
    properties (Access = private)
        Hash
        SubjectList
    end
        
    methods
        function obj = MimSubjectList(mim, modelUid, parameters)
            obj = obj@MimWSModel(mim, modelUid, parameters);
            obj.Hash = 0;
        end
        
        function [value, hash] = getValue(obj, modelList)
            obj.Hash = obj.Hash + 1;
            if isempty(obj.SubjectList)
                obj.update(modelList);
            end
            value = obj.SubjectList;
            hash = obj.Hash;
        end
        
        function update(obj, modelList)
            database = obj.Mim.GetImageDatabase();
            [projectNames, projectIds] = database.GetListOfProjects();
            strhash = int2str(obj.Hash);
            subjectList = {};
            for projectIndex = 1 : numel(projectNames)
                projectName = projectNames{projectIndex};
                projectId = projectIds{projectIndex};
                [names, ids, short_visible_names, num_series, num_patients_combined, patient_id_map] = database.GetListOfPatientNamesAndSeriesCount(projectId, true);
                for nameIndex = 1 : numel(names)
                    subjectId = ids{nameIndex};
                    parameters = {};
                    parameters.subjectId = subjectId;
                    parameters.projectName = projectName;
                    
                    [model, modelUid] = obj.getDerivedModel([], 'MimSubject', parameters, modelList);
                    subjectList{end + 1} = MimSubjectList.SubjectListEntry(modelUid, names{nameIndex}, subjectId, projectName, [], []);
                    
                end
            end
            obj.SubjectList = subjectList;
        end
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = 'MimSubjectList';
        end
    end
    
    methods (Static, Access = private)
        function subjectListEntry = SubjectListEntry(modelUid, label, id, project, uri, insert_date)
            subjectListEntry = struct();
            subjectListEntry.modelUid = modelUid;
            subjectListEntry.label = label;
            subjectListEntry.ID = id;
            subjectListEntry.project = project;
            subjectListEntry.URI = uri;
            subjectListEntry.insert_date = insert_date;
        end        
    end
end