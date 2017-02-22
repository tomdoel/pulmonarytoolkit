classdef MimModelCacheEntry < CoreBaseClass

    properties
        CurrentHash
        RemoteHash

        CachedValue
    end
    
    methods
        function obj = MimModelCacheEntry(currentHash, remoteHash)
            obj.CurrentHash = currentHash;
            obj.RemoteHash = remoteHash;
        end
        
        function update(obj, currentHash, remoteHash)
            obj.CurrentHash = currentHash;
            obj.RemoteHash = remoteHash;
        end
        
        function changed = hasChanged(obj)
            changed = ~isequal(obj.CurrentHash, obj.RemoteHash);
        end
        
        function modifyCurrentHashAndValue(obj, newHash, newValue)
            obj.CurrentHash = newHash;
            obj.CachedValue = newValue;
        end
        
        function updateValue(obj, newValue)
            obj.CachedValue = newValue;
        end
        
        function updateRemote(obj, newRemoteHash)
            obj.RemoteHash = newRemoteHash;
        end

        function Notify(obj, value)
            % ToDo: Notify listeners
            obj.CachedValue = value;
        end
    end
end

