classdef MimModelController < CoreBaseClass

    properties (Access = private)
        Mim
        ModelMap
    end
    
    methods
        function obj = MimModelController(mim)
            obj.Mim = mim;
            obj.ModelMap = MimModelMap(mim);
        end
        
        function [value, hash] = getValue(obj, modelId)
            [value, hash] = obj.ModelMap.getValue(modelId);
            obj.ModelMap.autoUpdate();
        end
        
        function setValue(obj, modelId, value)
            obj.ModelMap.setValue(modelId, value);
            obj.ModelMap.autoUpdate();
        end
        
        function modelId = buildModelId(obj, modelClassName, parameters)
            modelId = obj.ModelMap.buildModelId(modelClassName, parameters);
        end
        
        function clear(obj)
            obj.ModelMap.clear();
        end
    end
end
