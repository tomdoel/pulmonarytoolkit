classdef MimWebSocketServer < WebSocketServer
    
    properties (Constant)
        MimServerVersion = uint8(1)
        MimTextProtocolVersion = uint8(1)
        MimBinaryProtocolVersion = uint8(1)
    end
    
    methods
        function obj = MimWebSocketServer(varargin)
            obj@WebSocketServer(varargin{:});
        end
        
        function sendBinaryModel(obj, modelName, serverHash, lastClientHash, metaData, data)
            % Encodes model metadata and a data matrix into a blob and send
            % to clients. The data array will be sent as an int8 stream; it
            % is the client's responsibility to reconstruct this using the
            % metadata
            
            obj.sendToAll(MimWebSocketParser.EncodeAsBlob(modelName, serverHash, lastClientHash, metaData, data));
        end
        
        function sendTextModel(obj, modelName, serverHash, lastClientHash, metaData, data)
            % Encodes model metadata and text value into a JSON string and
            % send to clients. The data must be convertable to JSON, so it
            % is not suitable for binary data. The data will will be
            % reconstructed into a struct according to JSON, so assume the
            % values but not necessarily the data type will be preserved

            obj.sendToAll(MimWebSocketParser.EncodeAsString(modelName, serverHash, lastClientHash, metaData, data));
        end
    end
    
    methods (Access = protected)
        
        
        function onOpen(obj, conn, message)
            fprintf('%s\n',message);
        end
        
        function onTextMessage(obj, conn, message)
            [header, data] = obj.ParseString(message);
            fprintf('JSON received header: %s\n', header);
            fprintf('JSON received data: %s\n', data);
        end
        
        function onBinaryMessage(obj, conn, bytearray)
            [header, data] = obj.ParseBlob(bytearray);
            fprintf('JSON received header: %s\n', header);
            fprintf('JSON received data: %s\n', data);
        end
        
        function onError(obj,conn,message)
            fprintf('%s\n',message)
        end
        
        function onClose(obj,conn,message)
            fprintf('%s\n',message)
        end
    end
end
