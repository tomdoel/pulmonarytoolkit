classdef MimImageVolume < MimModel
    methods (Access = protected)
        function value = run(obj)
            dataset = obj.Callback.getModelValue(obj.Parameters.datasetModelId);
            value = dataset.GetResult('PTKOriginalImage');
        end
    end
end
