classdef MimLocalModelProxy < handle

    properties (Access = private)
        ModelCacheEntry
    end
    
    methods
        function obj = MimLocalModelProxy(modelCacheEntry)
            obj.ModelCacheEntry = modelCacheEntry;
        end
        
        function updateLastRemoteHash(obj, remoteHash)
            obj.ModelCacheEntry.updateRemote(remoteHash);
        end
        
        function updateValue(obj, currentHash, remoteHash, value)
            obj.ModelCacheEntry.update(currentHash, remoteHash);
        	obj.ModelCacheEntry.Notify(value);
        end
        
        function cache = getCache(obj)
        	cache = obj.ModelCacheEntry;
        end

        function value = getCurrentValue(obj)
            value = obj.ModelCacheEntry.CachedValue;
        end
    end
end