classdef MimModelCache < CoreBaseClass

    properties (Access = private)
        ModelDictionary
    end
    
    methods
        function obj = MimModelCache()
            obj.clear();
        end
        
        function entry = getModelCacheEntry(obj, modelId)
            if ~obj.ModelDictionary.isKey(modelId)
                obj.ModelDictionary(modelId) = MimModelCacheEntry([], []);
            end
            entry = obj.ModelDictionary(modelId);
        end
        
        function clear(obj)
            obj.ModelDictionary = containers.Map();
        end
    end
end