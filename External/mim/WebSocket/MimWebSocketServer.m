classdef MimWebSocketServer < WebSocketServer
    
    properties (Constant)
        MimServerVersion = uint8(1)
        MimTextProtocolVersion = uint8(1)
        MimBinaryProtocolVersion = uint8(1)
    end
    
    properties (Access = private)
        LocalCache              % Stores the local cache
        ConnectionCacheMap      % Stores the caches for each remote
    end
    
    methods
        function obj = MimWebSocketServer(port)
            obj@WebSocketServer(port);
            obj.ConnectionCacheMap = MimConnectionCacheMap();
            obj.LocalCache = MimModelCache();
        end
        
        function sendBinaryModel(obj, modelName, serverHash, lastClientHash, metaData, data)
            % Encodes model metadata and a data matrix into a blob and send
            % to clients. The data array will be sent as an int8 stream; it
            % is the client's responsibility to reconstruct this using the
            % metadata
            
            blob = MimWebSocketParser.EncodeAsBlob(modelName, serverHash, lastClientHash, metaData, data);
            obj.LogBinaryMessage('Sending', bytearray);
            obj.sendToAll(blob);
        end
        
        function sendTextModel(obj, modelName, serverHash, lastClientHash, metaData, data)
            % Encodes model metadata and text value into a JSON string and
            % send to clients. The data must be convertable to JSON, so it
            % is not suitable for binary data. The data will will be
            % reconstructed into a struct according to JSON, so assume the
            % values but not necessarily the data type will be preserved

            message = MimWebSocketParser.EncodeAsString(modelName, serverHash, lastClientHash, metaData, data);
            obj.LogStringMessage('Sending', message);
            obj.sendToAll(message);
        end

        function updateModelHashes(obj, modelName, localHash, remoteHash)
            obj.sendTextModel(modelName, localHash, remoteHash, [], []);
        end

        function updateModelValue(obj, modelName, localHash, remoteHash, value)
            if ischar(value) || iscell(value) || isstruct(value)
                obj.sendTextModel(modelName, localHash, remoteHash, [], value);
            else
                obj.sendBinaryModel(modelName, localHash, remoteHash, [], value);
            end
        end
        
        function updateLocalModelValue(obj, modelName, hash, value)
            % Get the local model cache
            localModelCache = obj.LocalCache.getModelCacheEntry(modelName);
            
            % Update the local model cache
            localModelCache.modifyCurrentHashAndValue(hash, value);
            
            localProxy = MimLocalModelProxy(localModelCache);
            
            for connection = obj.ConnectionCacheMap.getAllConnections
                % Get the remote model cache for this connection
                remoteModelCache = connection{1}.getModelCacheEntry(modelName);
                
                % Update models and trigger synchronisation
                MimModelUpdater.updateModel(localProxy, MimRemoteModelProxy(obj, modelName, [], remoteModelCache));
            end
        end        
    end
    
    methods (Access = protected)
        function onOpen(obj, conn, message)
            obj.ConnectionCacheMap.addConnection(conn);
        end
        
        function onTextMessage(obj, conn, message)
            obj.LogStringMessage('Received', message);
            [header, metaData, data] = MimWebSocketParser.ParseString(message);
            obj.parseMessage(conn, header, metaData, data);
        end
        
        function onBinaryMessage(obj, conn, bytearray)
            obj.LogBinaryMessage('Received', bytearray);
            [header, metaData, data] = MimWebSocketParser.ParseBlob(bytearray);
            obj.ParseMessage(conn, header, metaData, data);
        end
        
        function onError(obj,conn,message)
            fprintf('%s\n',message)
        end
        
        function onClose(obj, conn, message)
            obj.ConnectionCacheMap.deleteConnection(conn);
        end
        
        function LogStringMessage(obj, messageType, message)
            disp([messageType ' string message of length: ' int2str(length(message))]);
            [header, data] = MimWebSocketParser.ParseString(message);
            disp(' - Header: ');
            disp(header);
            disp(' - Data: ');
            disp(data);
        end
        
        function LogBinaryMessage(obj, messageType, blob)
            disp([messageType ' binary message of length: ' int2str(length(blob))]);
            [header, data] = MimWebSocketParser.ParseBlob(blob);
            disp(' - Header: ');
            disp(header);
        end
    end
    
    methods (Access = private)
        function parseMessage(obj, conn, header, metaData, data)
            disp(['Blob message received: version:' num2str(header.version) ' software version:' num2str(header.softwareVersion) ' model:' header.modelName ' hash server:' num2str(header.localHash) ' hash last client:' num2str(header.lastRemoteHash) ' value:' data]);
            
            % Get the remote model cache for this connection
            remoteModelCache = obj.ConnectionCacheMap.getConnection(conn).getModelCacheEntry(header.modelName);
            
            % Get the local model cache
            localModelCache = obj.LocalCache.getModelCacheEntry(header.modelName);
            
            % Update the remote model cache
            remoteModelCache.update(header.localHash, header.lastRemoteHash);
            
            % Update models and trigger synchronisation
            MimModelUpdater.updateModel(MimLocalModelProxy(localModelCache), MimRemoteModelProxy(obj, header.modelName, data, remoteModelCache));
        end        
    end
end
