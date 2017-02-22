classdef MimHashes < handle

    properties
        CurrentHash
        RemoteHash
    end
    
    methods
        function obj = MimHashes(currentHash, remoteHash)
            obj.CurrentHash = currentHash;
            obj.RemoteHash = remoteHash;
        end

        function changed = hasChanged(obj)
            changed = ~isequal(obj.CurrentHash, obj.RemoteHash);
        end
        
        function updateCurrent(obj, hashes)
            obj.CurrentHash = hashes.CurrentHash;
        end
        
        function updateRemote(obj, hashes)
            obj.RemoteHash = hashes.CurrentHash;
        end
        
        function updateCurrentAndRemote(obj, hashes)
            obj.CurrentHash = hashes.CurrentHash;
            obj.RemoteHash = hashes.CurrentHash;
        end
    end
    
end

