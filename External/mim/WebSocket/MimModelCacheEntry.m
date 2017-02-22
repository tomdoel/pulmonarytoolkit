classdef MimModelCacheEntry < CoreBaseClass

    properties
        CurrentHash
        RemoteHash
%         
%         Hashes
%         CachedValue
    end
    
    events
        
    end
    
    methods
        function obj = MimModelCacheEntry(currentHash, remoteHash)
            obj.CurrentHash = currentHash;
            obj.RemoteHash = remoteHash;
%             obj.Hashes = MimHashes(currentHash, remoteHash);
        end
        
        function update(obj, currentHash, remoteHash)
            obj.CurrentHash = currentHash;
            obj.RemoteHash = remoteHash;
        end
%         
%         function Notify(obj, value)
%             % ToDo: Notify listeners
%             obj.CachedValue = value;
%         end
    end
end

