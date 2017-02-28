classdef MimSubject < MimWSModel
    properties
        SubjectName
        SubjectId
        ProjectName
        ProjectId
        Hash
        SubjectOutput
    end

    methods
        function obj = MimSubject(mim, modelUid, parameters)
            obj = obj@MimWSModel(mim, modelUid, parameters);
            obj.SubjectName = parameters.subjectName;
            obj.ProjectName = parameters.projectName;
            obj.ProjectId = parameters.projectId;
            obj.SubjectId = parameters.subjectId;
            obj.Hash = 0;
        end
        
        function [value, hash] = getValue(obj, modelList)
            obj.Hash = obj.Hash + 1;
            if isempty(obj.SubjectOutput)
                obj.update(modelList);
            end
            value = obj.SubjectOutput;
            hash = obj.Hash;
        end
        
        function update(obj, modelList)
            database = obj.Mim.GetImageDatabase();
            
            datasets = database.GetAllSeriesForThisPatient(obj.ProjectId, obj.SubjectId, true);
            obj.SubjectOutput = struct;
            obj.SubjectOutput.subjectName = obj.SubjectName;
            obj.SubjectOutput.xnatProject = obj.ProjectName;
            obj.SubjectOutput.subjectXnatID = obj.SubjectId;
            obj.SubjectOutput.xnatInsertDate = '';
            seriesList = {};
            
            for seriesIndex = 1 : length(datasets)
                series = datasets{seriesIndex};
                seriesUid = series.SeriesUid;
                
                parameters = {};
                parameters.seriesName = series.Name;
                parameters.seriesUid = seriesUid;
                [model, modelUid] = obj.getDerivedModel([], 'MimSeries', parameters, modelList);
                seriesList{end + 1} = MimSubject.SeriesListEntry(modelUid, series.Name, series.Modality);
            end
            obj.SubjectOutput.seriesList = seriesList;
        end
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = parameters.subjectId;
        end
    end    
    
    methods (Static, Access = private)
        function seriesListEntry = SeriesListEntry(modelUid, seriesDescription, modality)
            persistent seriesNumber
            if isempty(seriesNumber)
                seriesNumber = 1;
            end
            seriesListEntry = struct();
            seriesListEntry.modelUid = modelUid;
            seriesListEntry.seriesDescription = seriesDescription;
            seriesListEntry.modality = modality;
            seriesListEntry.seriesNumber = seriesNumber;
            seriesNumber = seriesNumber + 1;
        end        
    end
end