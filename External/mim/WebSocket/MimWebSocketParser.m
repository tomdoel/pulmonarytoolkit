classdef MimWebSocketParser
    
    properties (Constant)
        MimServerSoftwareVersion = uint8(1)
        MimHashesOnlyTextProtocolVersion = uint8(1)
        MimTextProtocolVersion = uint8(1)
        MimBinaryProtocolVersion = uint8(1)
        
        MimPayloadData = 'data'
        MimPayloadHashes = 'hashes'
    end
    
    methods (Static)
        function [header, metaData, data] = ParseString(dataString)
            % Converts a data string into metadata and data

            json = loadjson(dataString);
            header = json;
            protocolVersion = json.version;
            if protocolVersion > 1
                error('Cannot process this protocol');
            end
            if isfield(json, 'metaData')
                metaData = json.metaData;
                header = rmfield(json, 'metaData');
            else
                metaData = [];
            end
            if isfield(json, 'data')
                data = json.data;
                header = rmfield(header, 'data');
            else
                data = [];
            end
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
            if isfield(header, 'metaData')
                metadata = header.metaData;
                header = rmfield(header, 'metaData');
            else
                metadata = [];
            end
            dataType = header.dataType;
            dataDims = header.dataDims;
            data = dataBlob(10 + headerLength : end);
            
            if isfield(metadata, 'StorageClass') && isfield(metadata, 'imageType')
                storageClassConstructor = str2func(metadata.StorageClass);
                data = storageClassConstructor(data, metadata.imageType);
            else
                data = typecast(data, dataType);
            end
            
            data = reshape(data, dataDims);
            header = rmfield(rmfield(header, 'dataType'), 'dataDims');
        end
        
        function dataBlob = EncodeAsBlob(modelName, serverHash, lastClientHash, payloadType, data)
            % Converts model metadata and binary value into a data blob
            
            if isa(data, 'MimStorageClass')
                [metaData, convertedData] = data.getStream();
                metaData.StorageClass = class(data);
            else
                disp('Warning: not a MimStorageClass');
                % Convert the data to an int8 array
                convertedData = typecast(data(:), 'int8');
                metaData = [];
            end
            
            % Construct the header, which includes transmission parameters and user-provided metadata
            header_struct = MimWebSocketParser.EncodeAsStruct(modelName, serverHash, lastClientHash, metaData, payloadType, []);
            header_struct.dataType = class(data);
            header_struct.dataDims = size(data);
            
            % Encode the header as a JSON string
            encodedHeader = MimWebSocketParser.EncodeAsJson(header_struct);

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
        
        function dataString = EncodeAsString(modelName, serverHash, lastClientHash, metaData, payloadType, data)
            dataString = MimWebSocketParser.EncodeAsJson(MimWebSocketParser.EncodeAsStruct(modelName, serverHash, lastClientHash, metaData, payloadType, data));
        end
        
        function json = EncodeAsJson(dataStruct)
            % Converts model metadata into a JSON string
            
            json = savejson([], dataStruct);
        end
        
        function dataStruct = EncodeAsStruct(modelName, serverHash, lastClientHash, metaData, payloadType, data)
            % Converts model metadata into a JSON string
            
            dataStruct = struct();
            dataStruct.version = MimWebSocketParser.MimTextProtocolVersion;
            dataStruct.softwareVersion = MimWebSocketParser.MimServerSoftwareVersion;
            dataStruct.modelName = modelName;
            dataStruct.localHash = serverHash;
            dataStruct.lastRemoteHash = lastClientHash;
            dataStruct.payloadType = payloadType;
            dataStruct.metaData = metaData;
            if ~isempty(data)
                dataStruct.value = data;
            end
        end        
    end
end