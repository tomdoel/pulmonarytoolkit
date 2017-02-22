classdef MimLocalModelCache < CoreBaseClass

    properties
        ModelDictionary
    end
    
    methods
        function obj = MimLocalModelCache()
            obj.ModelDictionary = containers.Map;
        end
        
        function entry = getModelCacheEntry(obj, modelName)
            if ~obj.ModelDictionary.isKey(modelName)
                obj.ModelDictionary(modelName) = MimLocalModelCacheEntry([], []);
            end
            entry = obj.ModelDictionary(modelName);
        end
    end
end