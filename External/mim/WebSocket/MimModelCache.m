classdef MimModelCache < CoreBaseClass

    properties (Access = private)
        ModelDictionary
    end
    
    methods
        function obj = MimModelCache()
            obj.ModelDictionary = containers.Map;
        end
        
        function clear(obj)
            obj.ModelDictionary = containers.Map;
        end
        
        function entry = getModelCacheEntry(obj, modelName)
            if ~obj.ModelDictionary.isKey(modelName)
                obj.ModelDictionary(modelName) = MimModelCacheEntry([], []);
            end
            entry = obj.ModelDictionary(modelName);
        end
    end
end