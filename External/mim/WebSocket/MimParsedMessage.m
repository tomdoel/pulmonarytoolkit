classdef MimParsedMessage < handle

    properties
        version
        softwareVersion
        modelName
        localHash
        lastRemoteHash
        modelCacheEntry
        metaData
        value
    end
    
    methods
        function obj = MimParsedMessage(version, softwareVersion, modelName, localHash, lastRemoteHash, metaData, value)
            obj.version = version;
            obj.softwareVersion = softwareVersion;
            obj.modelName = modelName;
            obj.localHash = localHash;
            obj.lastRemoteHash = lastRemoteHash;
            obj.modelCacheEntry = MimModelCacheEntry(localHash, lastRemoteHash);
            obj.metaData = metaData;
            obj.value = value;
        end
    end
end

