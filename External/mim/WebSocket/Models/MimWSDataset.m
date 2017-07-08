classdef MimWSDataset < MimModel
    methods
        function obj = MimWSDataset(modelId, parameters, modelMap, autoUpdate)
            obj = obj@MimModel(modelId, parameters, modelMap, autoUpdate);            
        end
    end
    
    methods (Access = protected)        
        function value = run(obj)
            seriesUid = obj.Parameters.seriesUid;
            value = obj.ModelMap.getMim().CreateDatasetFromUid(seriesUid);
        end
    end
end