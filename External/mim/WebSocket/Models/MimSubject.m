classdef MimSubject < MimWSModel
    properties
        SubjectId
        ProjectName
        Hash
        SeriesList
    end

    methods
        function obj = MimSubject(mim, modelUid, parameters)
            obj = obj@MimWSModel(mim, modelUid, parameters);
            obj.ProjectName = parameters.projectName;
            obj.SubjectId = parameters.subjectId;
            obj.Hash = 0;
        end
        
        function [value, hash] = getValue(obj, modelList)
            obj.Hash = obj.Hash + 1;
            if isempty(obj.SeriesList)
                obj.update(modelList);
            end
            value = obj.SeriesList;
            hash = obj.Hash;
        end
        
        function update(obj, modelList)
            database = obj.Mim.GetImageDatabase();
            
            datasets = database.GetAllSeriesForThisPatient(obj.ProjectName, obj.SubjectId, true);
            seriesList = {};
            
            for seriesIndex = 1 : length(datasets)
                series = datasets{seriesIndex};
                seriesUid = series.SeriesUid;
                
                parameters = {};
                parameters.SeriesName = series.Name;
                parameters.SeriesUid = seriesUid;
                [model, modelUid] = obj.getDerivedModel([], 'MimSeries', parameters, modelList);
                seriesList{end + 1} = MimSubject.SeriesListEntry(modelUid, series.Name, series.Modality);
            end
            obj.SeriesList = seriesList;
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