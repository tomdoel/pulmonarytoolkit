classdef MimWebSocketParser
    
    properties (Constant)
        MimServerVersion = uint8(1)
        MimTextProtocolVersion = uint8(1)
        MimBinaryProtocolVersion = uint8(1)
    end
    
    methods (Static)
        function [header, metaData, data] = ParseString(dataString)
            % Converts a data string into metadata and data

            json = loadjson(dataString);
            protocolVersion = json.version;
            if protocolVersion > 1
                error('Cannot process this protocol');
            end
            metaData = json.metaData;
            data = json.value;
            header = rmfield(rmfield(json, 'value'), 'metaData');
        end
        
        function [header, metadata, data] = ParseBlob(dataBlob)
            % Converts a data array into metadata and a data blob
            
            protocolVersion = dataBlob(1);
            if protocolVersion > 1
                error('Cannot process this protocol');
            end
            headerLength = typecast(dataBlob(2:5), 'uint32');
            dataLength = typecast(dataBlob(6:9), 'uint32');
            header = loadjson(char(dataBlob(10 : 9 + headerLength)));
            metadata = header.metaData;
            dataType = header.dataType;
            dataDims = header.dataDims;
            data = dataBlob(10 + headerLength : end);
            data = typecast(data, dataType);
            data = reshape(data, dataDims);
            header = rmfield(rmfield(rmfield(header, 'dataType'), 'dataDims'), 'metaData');
        end
        
        function dataBlob = EncodeAsBlob(modelName, serverHash, lastClientHash, metaData, data)
            % Converts model metadata and binary value into a data blob
            
            % COnstruct the header, which includes transmission parameters and user-provided metadata
            header_struct = MimWebSocketParser.EncodeAsStruct(modelName, serverHash, lastClientHash, metaData, []);
            header_struct.dataType = class(data);
            header_struct.dataDims = size(data);
            
            % Encode the header as a JSON string
            encodedHeader = MimWebSocketParser.EncodeAsJson(header_struct);
            
            % Convert the data to an int8 array
            convertedData = typecast(data(:), 'int8');
            
            % Construct the data blob
            dataBlob = int8([]);
            
            % Add protocol version
            dataBlob(1) = typecast(MimWebSocketParser.MimBinaryProtocolVersion, 'int8');
            
            % Add header length
            encodedHeaderLength = uint32(length(encodedHeader));
            dataBlob(2:5) = typecast(encodedHeaderLength, 'int8');
            
            % Add data length
            convertedDataLength = uint32(length(convertedData));
            dataBlob(6 : 9) = typecast(convertedDataLength, 'int8');

            % Add header (JSON string encoded as int8)
            dataBlob(10 : 9 + encodedHeaderLength) = int8(encodedHeader);

            % Add data (encoded as int8)
            dataBlob(10 + encodedHeaderLength : 9 + encodedHeaderLength + convertedDataLength) = convertedData;
        end
        
        function dataString = EncodeAsString(modelName, serverHash, lastClientHash, metaData, data)
            dataString = MimWebSocketParser.EncodeAsJson(MimWebSocketParser.EncodeAsStruct(modelName, serverHash, lastClientHash, metaData, data));
        end
        
        function json = EncodeAsJson(dataStruct)
            % Converts model metadata into a JSON string
            
            json = savejson([], dataStruct);
        end
        
        function dataStruct = EncodeAsStruct(modelName, serverHash, lastClientHash, metaData, data)
            % Converts model metadata into a JSON string
            
            dataStruct = struct();
            dataStruct.version = MimWebSocketParser.MimTextProtocolVersion;
            dataStruct.serverVersion = MimWebSocketServer.MimServerVersion;
            dataStruct.modelName = modelName;
            dataStruct.localHash = serverHash;
            dataStruct.lastRemoteHash = lastClientHash;
            if ~isempty(metaData)
                dataStruct.metaData = metaData;
            end
            if ~isempty(data)
                dataStruct.value = data;
            end
        end        
    end
end