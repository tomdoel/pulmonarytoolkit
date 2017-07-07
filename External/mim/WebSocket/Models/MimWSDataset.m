classdef MimWSDataset < MimModel
    properties
        Dataset
        SeriesUid
    end
        
    methods
        function obj = MimWSDataset(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);            
            obj.SeriesUid = parameters.seriesUid;
        end
        
        function value = run(obj)
            if isempty(obj.Dataset)
                obj.Dataset = obj.Mim.CreateDatasetFromUid(obj.SeriesUid);
            end
            value = obj.Dataset;
        end
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = [parameters.seriesUid '-MIMDATASET'];
        end
    end    
end