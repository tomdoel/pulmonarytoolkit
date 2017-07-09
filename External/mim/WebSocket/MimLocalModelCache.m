classdef MimLocalModelCache < CoreBaseClass

    properties (Access = private)
        Controller
        ModelDictionary
    end
    
    methods
        function obj = MimLocalModelCache(controller)
            obj.Controller = controller;
            obj.ModelDictionary = containers.Map;
        end
        
        function entry = getModelCacheEntry(obj, modelName)
            if ~obj.ModelDictionary.isKey(modelName)
                obj.ModelDictionary(modelName) = MimLocalModelCacheEntry([], [], obj.Controller, modelName);
            end
            entry = obj.ModelDictionary(modelName);
        end
        
        function clear(obj)
            obj.ModelDictionary = containers.Map();
        end
    end
end