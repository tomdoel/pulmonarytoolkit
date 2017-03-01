classdef MimRemoteModelProxy < handle

    properties (Access = private)
        Websocket
        ModelName
        ModelValue
        PayloadType
        ModelCacheEntry
    end
    
    methods
        function obj = MimRemoteModelProxy(websocket, modelName, modelValue, payloadType, modelCacheEntry)
            obj.Websocket = websocket;
            obj.ModelName = modelName;
            obj.ModelValue = modelValue;
            obj.PayloadType = payloadType;
            obj.ModelCacheEntry = modelCacheEntry;
        end
        
        function updateHashes(obj, currentHash, remoteHash)
            obj.Websocket.updateModelHashes(obj.ModelName, currentHash, remoteHash);
        end
    
        function updateAndNotify(obj, currentHash, remoteHash, value)
            obj.Websocket.updateModelValue(obj.ModelName, currentHash, remoteHash, value);
        end

        function cache = getCache(obj)
        	cache = obj.ModelCacheEntry;
        end

        function isProvided = isValueProvided(obj)
            isProvided = strcmp(obj.PayloadType, MimWebSocketParser.MimPayloadData);
        end
    
        function value = getCurrentValue(obj)
            value = obj.ModelValue;
        end
    end
end