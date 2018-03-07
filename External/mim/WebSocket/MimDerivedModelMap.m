classdef MimDerivedModelMap < handle

    properties (Access = private)
        DerivedModelMap
    end
    
    methods
        function obj = MimDerivedModelMap()
            obj.DerivedModelMap = containers.Map();
        end
        
        function modelMap = getModelMap(obj, modelName)
            if obj.DerivedModelMap.isKey(modelName)
                modelMap = obj.DerivedModelMap(modelName);
            else
                modelMap = containers.Map;
                obj.DerivedModelMap(modelName) = modelMap;
            end
        end
    end
end