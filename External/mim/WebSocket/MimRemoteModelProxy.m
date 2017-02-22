classdef MimRemoteModelProxy < handle

    properties (Access = private)
        Websocket
        Hashes
        ModelName
        ModelValue
        ModelCacheEntry
    end
    
    methods
        function obj = MimRemoteModelProxy(websocket, modelName, modelValue, modelCacheEntry)
            obj.Websocket = websocket;
            obj.Hashes = modelCacheEntry.Hashes;
            obj.ModelName = modelName;
            obj.ModelValue = modelValue;
            obj.ModelCacheEntry = modelCacheEntry;
        end
        
        function updateCurrentHash(obj, currentHash)
            obj.Websocket.updateModelHashes(obj.ModelName, currentHash);
        end
    
        function updateLastRemoteHash(obj, remoteHash)
            obj.Websocket.updateModelHashes(obj.ModelName, remoteHash);
        end

        function updateCurrentValueToRemoteValue(obj, currentHash, value)
            obj.Websocket.updateModelValue(obj.ModelName, currentHash, value);
        end

        function value = getCurrentValue(obj)
            value = obj.ModelValue;
        end
        
        function hashes = getHashes(obj)
        	hashes = obj.Hashes;
        end
    end
end