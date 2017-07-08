classdef MimImageVolume < MimModel
    methods
        function obj = MimImageVolume(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);
        end
    end
    
    methods (Access = protected)
        function value = run(obj)
            dataset = obj.getModelValue(obj.Parameters.datasetModelId);
            value = dataset.GetResult('PTKOriginalImage');
        end
    end
end
