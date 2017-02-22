classdef MimRemoteModelProxy < handle

    properties (Access = private)
        Websocket
        ModelName
        ModelValue
        ModelCacheEntry
    end
    
    methods
        function obj = MimRemoteModelProxy(websocket, modelName, modelValue, modelCacheEntry)
            obj.Websocket = websocket;
            obj.ModelName = modelName;
            obj.ModelValue = modelValue;
            obj.ModelCacheEntry = modelCacheEntry;
        end
        
        function updateHashes(obj, currentHash, remoteHash)
            obj.Websocket.updateModelHashes(obj.ModelName, currentHash, remoteHash);
        end
    
        function updateValue(obj, currentHash, remoteHash, value)
            obj.Websocket.updateModelValue(obj.ModelName, currentHash, remoteHash, value);
        end

        function cache = getCache(obj)
        	cache = obj.ModelCacheEntry;
        end

        function value = getCurrentValue(obj)
            value = obj.ModelValue;
        end
    end
end