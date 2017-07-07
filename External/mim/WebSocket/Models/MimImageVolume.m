classdef MimImageVolume < MimModel
    properties
        DatasetModelId
        Image
    end

    methods
        function obj = MimImageVolume(modelId, parameters, modelMap, autoUpdat)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdat);
            obj.DatasetModelId = parameters.datasetModelId;
        end
        
        function value = run(obj)
            if isempty(obj.Image)
                dataset = obj.getValue(obj.DatasetModelId);
                obj.Image = dataset.GetResult('PTKOriginalImage');
            end
            value = obj.Image;
        end
    end
    
    methods (Static)
        function key = getKeyFromParameters(parameters)
            key = [parameters.seriesUid '-VOL'];
        end
    end
end