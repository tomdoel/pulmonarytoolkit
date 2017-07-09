classdef MimWebSocketServer < WebSocketServer
    
    properties (Access = private)
        LocalCache              % Stores the local cache
        ConnectionCacheMap      % Stores the caches for each remote
        LocalModelCallback      % For requesting local model value
        
        Debugging = false
    end
    
    methods
        function obj = MimWebSocketServer(port, localModelCallback)
            obj@WebSocketServer(port);
            obj.ConnectionCacheMap = MimConnectionCacheMap();
            obj.LocalCache = MimLocalModelCache(localModelCallback);
            obj.LocalModelCallback = localModelCallback;
        end
        
        function sendBinaryModel(obj, modelName, serverHash, lastClientHash, payloadType, data)
            % Encodes model metadata and a data matrix into a blob and send
            % to clients. The data array will be sent as an int8 stream; it
            % is the client's responsibility to reconstruct this using the
            % metadata
            
            blob = MimWebSocketParser.EncodeAsBlob(modelName, serverHash, lastClientHash, payloadType, data);
            obj.LogBinaryMessage('Sending', blob);
            obj.sendToAll(blob);
        end
        
        function sendTextModel(obj, modelName, serverHash, lastClientHash, metaData, payloadType, data)
            % Encodes model metadata and text value into a JSON string and
            % send to clients. The data must be convertable to JSON, so it
            % is not suitable for binary data. The data will will be
            % reconstructed into a struct according to JSON, so assume the
            % values but not necessarily the data type will be preserved

            message = MimWebSocketParser.EncodeAsString(modelName, serverHash, lastClientHash, metaData, payloadType, data);
            obj.LogStringMessage('Sending', message);
            obj.sendToAll(message);
        end

        function updateModelHashes(obj, modelName, localHash, remoteHash)
            obj.sendTextModel(modelName, localHash, remoteHash, [], MimWebSocketParser.MimPayloadHashes, []);
        end

        function updateModelValue(obj, modelName, localHash, remoteHash, value)
            if ischar(value) || iscell(value) || isstruct(value)
                obj.sendTextModel(modelName, localHash, remoteHash, [], MimWebSocketParser.MimPayloadData, value);
            else
                obj.sendBinaryModel(modelName, localHash, remoteHash, MimWebSocketParser.MimPayloadData, value);
            end
        end
        
        function updateLocalModelValue(obj, modelName, hash, value)
            % Get the local model cache
            localModelCache = obj.LocalCache.getModelCacheEntry(modelName);
            
            % Update the local model cache
            localModelCache.modifyCurrentHashAndValue(hash, value);
            
            for connection = obj.ConnectionCacheMap.getAllConnections()
                % Get the remote model cache for this connection
                remoteModelCache = connection{1}.getModelCacheEntry(modelName);
                
                % Update models and trigger synchronisation
                MimModelUpdater.updateModel(localModelCache, MimRemoteModelProxy(obj, modelName, [], false, remoteModelCache));
            end
        end
        
        function clearModels(obj)
            obj.LocalCache.clear();
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
            if obj.Debugging
                disp([messageType ' string message of length: ' int2str(length(message))]);
                [header, metaData, data] = MimWebSocketParser.ParseString(message);
                disp(' - Header: ');
                disp(header);
                disp(' - metaData: ');
                disp(metaData);
                disp(' - Data: ');
                disp(data);
            end
        end
        
        function LogBinaryMessage(obj, messageType, blob)
            if obj.Debugging
                disp([messageType ' binary message of length: ' int2str(length(blob))]);
                [header, metaData, data] = MimWebSocketParser.ParseBlob(blob);
                disp(' - Header: ');
                disp(header);
                disp(' - metaData: ');
                disp(metaData);
            end
        end
    end
    
    methods (Access = private)
        function parseMessage(obj, conn, header, metaData, data)
%             disp(['Blob message received: version:' num2str(header.version) ' software version:' num2str(header.softwareVersion) ' model:' header.modelName ' hash server:' num2str(header.localHash) ' hash last client:' num2str(header.lastRemoteHash) ' value:' data]);
            
            if isfield(header, 'modelName')
                % Get the remote model cache for this connection
                remoteModelCache = obj.ConnectionCacheMap.getConnection(conn).getModelCacheEntry(header.modelName);

                % Get the local model cache
                localModelCache = obj.LocalCache.getModelCacheEntry(header.modelName);

                % Update the remote model cache
                remoteModelCache.updateHashes(header.localHash, header.lastRemoteHash);

                if isempty(localModelCache.CurrentHash) && isempty(remoteModelCache.CurrentHash)
                    % If the remote has no value then assume it is requesting a
                    % value from our local cache

                    [value, hash] = obj.LocalModelCallback.getValue(header.modelName);
                    obj.updateLocalModelValue(header.modelName, hash, value);
                else
                    % Update models and trigger synchronisation
                    payloadType = header.payloadType;
                    MimModelUpdater.updateModel(localModelCache, MimRemoteModelProxy(obj, header.modelName, data, payloadType, remoteModelCache));
                end
            else
                disp('ERROR: Empty model name received');
            end
        end        
    end
end
