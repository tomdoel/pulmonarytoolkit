classdef MimModelCacheEntry < CoreBaseClass

    properties
        CurrentHash
        RemoteHash
    end
    
    methods
        function obj = MimModelCacheEntry(currentHash, remoteHash)
            obj.CurrentHash = currentHash;
            obj.RemoteHash = remoteHash;
        end
        
        function updateHashes(obj, currentHash, remoteHash)
            obj.CurrentHash = currentHash;
            obj.RemoteHash = remoteHash;
        end
        
        function changed = hasChanged(obj)
            changed = ~isequal(obj.CurrentHash, obj.RemoteHash);
        end
    end
end

