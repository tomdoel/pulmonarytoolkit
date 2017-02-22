classdef MimLocalModelProxy < handle

    properties (Access = private)
        ClientCacheEntry
        Hashes
    end
    
    methods
        function obj = MimLocalModelProxy(clientCacheEntry)
            obj.ClientCacheEntry = clientCacheEntry;
            obj.Hashes = obj.ClientCacheEntry.Hashes;
        end
        
        function updateCurrentHash(obj, currentHash)
            obj.Hashes.updateCurrent(currentHash);
        end
    
        function updateLastRemoteHash(obj, remoteHash)
            obj.Hashes.updateRemote(remoteHash);
        end

        function updateCurrentValueToNewLocalValue(obj, currentHash, value)
            obj.Hashes.updateCurrent(currentHash);
        	obj.ClientCacheEntry.Notify(value);
        end
        
        function updateCurrentValueToRemoteValue(obj, currentHash, value)
            obj.Hashes.updateCurrentAndRemote(currentHash);
        	obj.ClientCacheEntry.notify(value);
        end

        function value = getCurrentValue(obj)
            value = obj.ClientCacheEntry.cachedValue;
        end
        
        function hashes = getHashes(obj)
        	hashes = obj.Hashes;
        end
    end
end