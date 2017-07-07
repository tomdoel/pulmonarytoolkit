classdef MimSubject < MimModel
    properties
        SubjectName
        SubjectId
        ProjectName
        ProjectId
%         Hash
        SubjectOutput
    end

    methods
        function obj = MimSubject(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
            obj.SubjectName = parameters.subjectName;
            obj.ProjectName = parameters.projectName;
            obj.ProjectId = parameters.projectId;
            obj.SubjectId = parameters.subjectId;
            obj.Hash = 0;
        end
        
        function value = run(obj)
%             obj.Hash = obj.Hash + 1;
            if isempty(obj.SubjectOutput)
                obj.updateSubjectOutput();
            end
            value = obj.SubjectOutput;
%             hash = obj.Hash;
        end
        
        function updateSubjectOutput(obj)
            database = obj.ModelMap.getMim().GetImageDatabase();
            
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
                parameters.subjectModelId = obj.ModelId;
                modelId = obj.buildModelId('MimSeries', parameters);
                seriesList{end + 1} = MimSubject.SeriesListEntry(modelId, series.Name, series.Modality);
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