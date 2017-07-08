classdef MimWSSubject < MimModel
    methods
        function obj = MimWSSubject(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end 
    end
    
    methods (Access = protected)
        function value = run(obj)
            database = obj.ModelMap.getMim().GetImageDatabase();
            subjectName = obj.Parameters.subjectName;
            projectName = obj.Parameters.projectName;
            projectId = obj.Parameters.projectId;
            subjectId = obj.Parameters.subjectId;
            
            datasets = database.GetAllSeriesForThisPatient(projectId, subjectId, true);
            seriesList = {};
            
            for seriesIndex = 1 : length(datasets)
                series = datasets{seriesIndex};
                seriesUid = series.SeriesUid;
                
                parameters = {};
                parameters.seriesName = series.Name;
                parameters.seriesUid = seriesUid;
                parameters.subjectModelId = obj.ModelId;
                modelId = obj.buildModelId('MimWSSeries', parameters);
                seriesList{end + 1} = MimWSSubject.SeriesListEntry(modelId, series.Name, series.Modality);
            end
            value = seriesList;
        end
    end
    
    methods (Static, Access = private)
        function seriesListEntry = SeriesListEntry(modelId, seriesDescription, modality)
            persistent seriesNumber
            if isempty(seriesNumber)
                seriesNumber = 1;
            end
            seriesListEntry = struct();
            seriesListEntry.modelId = modelId;
            seriesListEntry.seriesDescription = seriesDescription;
            seriesListEntry.modality = modality;
            seriesListEntry.seriesNumber = seriesNumber;
            seriesNumber = seriesNumber + 1;
        end        
    end
end