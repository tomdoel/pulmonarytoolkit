classdef MimModelController < CoreBaseClass

    properties (Access = private)
        ModelMap
    end
    
    methods
        function obj = MimModelController()
            obj.ModelMap = MimModelMap();
        end
        
        function value = getValue(obj, modelId)
            value = obj.ModelMap.getValue(modelId);
            obj.ModelMap.autoUpdate();
        end
        
        function setValue(obj, modelId, value)
            obj.ModelMap.setValue(modelId, value);
            obj.ModelMap.autoUpdate();
        end
        
        function modelId = buildModelId(obj, modelClassName, parameters)
            modelId = obj.ModelMap.buildModelId(modelClassName, parameters);
        end
    end
end
