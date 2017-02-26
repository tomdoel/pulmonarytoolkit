classdef MimSeries < MimWSModel
    properties
        SubjectId
        SeriesUid
        SeriesName
        Hash
        SeriesList
        SeriesModelMap
    end
        
    methods
        function obj = MimSeries(mim, modelUid, parameters)
            obj = obj@MimWSModel(mim, modelUid, parameters);            
            obj.SeriesUid = parameters.seriesUid;
            obj.SeriesName = parameters.seriesName;
            obj.Hash = 0;
            obj.SeriesModelMap = containers.Map;
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
            
            datasets = database.GetAllSeriesForThisPatient(obj.ProjectId, obj.SubjectId, true);
            seriesList = {};
            
            for seriesIndex = 1 : length(datasets)
                series = datasets{seriesIndex};
                seriesUid = series.SeriesUid;
                 
                if obj.SeriesModelMap.isKey(seriesUid)
                    model = obj.SeriesModelMap(seriesUid);
                    modelUid = model.ModelUid;
                    modelList.addModel(obj.Mim, modelUid, model);
                else
                    modelUid = CoreSystemUtilities.GenerateUid();
                    numImages = series.NumberOfImages;
                    
                    model = MimSeries(obj.Mim, modelUid, seriesUid);
                    obj.SeriesModelMap(seriesUid) = model;
                end
                seriesList{end + 1} = MimSubject.SeriesListEntry(modelUid, series.Name, series.Modality);

                % Add model to list, or verify it matches the existing
                % model in the lsit
                modelList.addModel(obj.Mim, modelUid, model);
            end
            obj.SeriesList = seriesList;
        end
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = parameters.seriesUid;
        end
    end    
end