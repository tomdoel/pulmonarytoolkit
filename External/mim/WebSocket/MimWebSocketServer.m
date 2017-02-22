classdef MimWebSocketServer < WebSocketServer
    
    properties (Constant)
        MimServerVersion = uint8(1)
        MimTextProtocolVersion = uint8(1)
        MimBinaryProtocolVersion = uint8(1)
    end
    
    properties (Access = private)
        LocalCache              % Stores the local cache
        ConnectionCacheMap      % Stores the caches for each remote
        ReceiveMessageCallback 
    end
    
    methods
        function obj = MimWebSocketServer(port, receiveMessageCallback)
            obj@WebSocketServer(port);
            obj.ReceiveMessageCallback = receiveMessageCallback;
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

        function updateModelHashes(obj, modelName, hashes)
            obj.sendTextModel(modelName, hashes.RemoteHash, hashes.CurrentHash, [], []);
        end

        function updateModelValue(obj, modelName, hashes, value)
            if ischar(value)
                obj.sendTextModel(modelName, hashes.RemoteHash, hashes.CurrentHash, [], value);
            else
                obj.sendBinaryModel(modelName, hashes.RemoteHash, hashes.CurrentHash, [], value);
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
            obj.ParseMessage(conn, header, metaData, data);
%             parsed = MimParsedMessage(header.version, header.softwareVersion, header.modelName, header.localHash, header.lastRemoteHash, metaData, data);
%             obj.ParseMessage
%             obj.ConnectionCacheMap.getConnection(conn);
%             obj.ReceiveMessageCallback(parsed);
        end
        
        function onBinaryMessage(obj, conn, bytearray)
            obj.LogBinaryMessage('Received', bytearray);
            [header, metaData, data] = MimWebSocketParser.ParseBlob(bytearray);
            obj.ParseMessage(conn, header, metaData, data);
%             parsed = MimParsedMessage(header.version, header.softwareVersion, header.modelName, header.localHash, header.lastRemoteHash, metaData, data);
%             obj.ReceiveMessageCallback(parsed);
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
            parsedMessage = MimParsedMessage(header.version, header.softwareVersion, header.modelName, header.localHash, header.lastRemoteHash, metaData, data);
            disp(['Blob message received: version:' parsedMessage.version ' software version:' parsedMessage.softwareVersion ' model:' parsedMessage.modelName ' hash server:' parsedMessage.localHash ' hash last client:' parsedMessage.lastRemoteHash ' value:' parsedMessage.value]);
            
            % Get the remote model cache for this connection
            remoteModelCache = obj.ConnectionCacheMap.getConnection(conn).getModelCacheEntry(parsedMessage.modelName);
            
            % Get the local model cache
            localModelCache = obj.LocalCache.getModelCacheEntry(parsedMessage.modelName);
            
            % Update the remote model cache
            remoteModelCache.update(header.localHash, header.lastRemoteHash);
            
%             obj.ParseMessage
%             obj.ReceiveMessageCallback(parsed);
            obj.Updater.updateModel(MimLocalModelProxy(localModelCache), MimRemoteModelProxy(obj.WebSocketServer, parsedMessage.modelName, parsedMessage.value, remoteModelCache));
        end        
    end
end
