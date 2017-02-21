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
    end
    
    methods (Access = protected)
        
        
        function onOpen(obj, conn, message)
            fprintf('%s\n',message);
        end
        
        function onTextMessage(obj, conn, message)
            obj.LogStringMessage('Received', message);
            [header, data] = MimWebSocketParser.ParseString(message);
        end
        
        function onBinaryMessage(obj, conn, bytearray)
            obj.LogBinaryMessage('Received', bytearray);
            [header, data] = MimWebSocketParser.ParseBlob(bytearray);
        end
        
        function onError(obj,conn,message)
            fprintf('%s\n',message)
        end
        
        function onClose(obj,conn,message)
            fprintf('%s\n',message)
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
end
