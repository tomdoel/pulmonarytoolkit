classdef MimSubjectList < MimWSModel
    properties (Access = private)
        Hash
        Mim
        SubjectList
    end
        
    methods
        function obj = MimSubjectList(mim)
            obj.Mim = mim;
            obj.Hash = 0;
        end
        
        function [value, hash] = getValue(obj)
            obj.Hash = obj.Hash + 1;
            if isempty(obj.SubjectList)
                obj.update();
            end
            value = obj.SubjectList;
            hash = obj.Hash;
        end
        
        function update(obj)
            database = obj.Mim.GetImageDatabase();
            [projectNames, projectIds] = database.GetListOfProjects();
            strhash = int2str(obj.Hash);
            subjectList = {};
            for projectIndex = 1 : numel(projectNames)
                projectName = projectNames{projectIndex};
                projectId = projectIds{projectIndex};
                [names, ids, short_visible_names, num_series, num_patients_combined, patient_id_map] = database.GetListOfPatientNamesAndSeriesCount(projectId, true);
                for nameIndex = 1 : numel(names)
                    subjectList{end + 1} = MimSubjectList.SubjectListEntry(names{nameIndex}, ids{nameIndex}, projectName, [], []);
                end
            end
            obj.SubjectList = subjectList;
        end
    end
    
    methods (Static, Access = private)
        function subjectListEntry = SubjectListEntry(label, id, project, uri, insert_date)
            subjectListEntry = struct();
            subjectListEntry.label = label;
            subjectListEntry.ID = id;
            subjectListEntry.project = project;
            subjectListEntry.URI = uri;
            subjectListEntry.insert_date = insert_date;
        end        
    end
end