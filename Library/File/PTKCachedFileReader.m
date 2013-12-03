classdef PTKCachedFileReader < handle
    % PTKCachedFileReader. A helper class to assist with reading a file
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        % The size of the text buffer to be read in. It is safe to change this
        % value while file reading is in progress
        MaxFileCacheSize = uint32(600000)
    end
    
    properties (Access = private)
        FileText
        FileId
        
        FilePointer
        FileCache
        SizeOfCurrentCache
        FlipEndian
        
        EofReached
    end
    
    methods
        function obj = PTKCachedFileReader(file_path, file_name, transfer_syntax, reporting)
            
            
            full_file_name = fullfile(file_path, file_name);
            
            computer_endian = PTKSystemUtilities.GetComputerEndian;
            obj.FlipEndian = (computer_endian ~= transfer_syntax.Endian);
            
            switch transfer_syntax.Endian
                case PTKEndian.BigEndian
                    file_encoding = 'b';
                case PTKEndian.LittleEndian
                    file_encoding = 'l';
                otherwise
                    error('Unknown file encoding');
            end
                        
            switch transfer_syntax.CharacterEncoding
                case PTKDicomCharacterEncoding.UTF8
                    character_encoding = 'UTF-8';
                otherwise
                    error('Unknown character encoding');
            end
            
            file_id = fopen(full_file_name, 'r', file_encoding, character_encoding);
            
            if (file_id == -1)
                reporting.Error('PTKFileReader:CannotOpenFile', ['Unable to open file ' full_file_name]);
                obj.EofReached = true;
                obj.FileId = [];
            else
                obj.FileId = file_id;
                obj.EofReached = false;
                obj.ReadNextFileBlock;
            end
        end
        

        function data = ReadData(obj, data_type, number_of_bytes)
            data = ReadBytesFromCache(obj, number_of_bytes);            
            data = typecast(data, data_type);
            if obj.FlipEndian
                data = swapbytes(data);
            end
        end
        
        function data = ReadString(obj, number_of_bytes)
            data = char(ReadBytesFromCache(obj, number_of_bytes));
        end
        
        function wrapper = ReadDataIntoWrapper(obj, data_type, number_of_bytes)
            wrapper = PTKWrapper;
            wrapper.RawImage = ReadBytesFromCache(obj, number_of_bytes);
            
            if strcmp(data_type, 'char')
                wrapper.RawImage = char(wrapper.RawImage);
            else
                wrapper.RawImage = typecast(wrapper.RawImage, data_type);
                if obj.FlipEndian
                    wrapper.RawImage = swapbytes(wrapper.RawImage);
                end
            end
        end
        
        function Close(obj)
            if ~isempty(obj.FileId)
                fclose(obj.FileId);
                obj.FileId = [];
            end
        end
        
        function delete(obj)
            obj.Close;
        end
        
        function more_data = MoreDataToRead(obj)
            more_data_in_cache = ~isempty(obj.FileCache) && (obj.FilePointer <= obj.SizeOfCurrentCache);
            more_data_to_read_from_disk = ~obj.EofReached;
            more_data = more_data_in_cache || more_data_to_read_from_disk;
        end
        
        function Skip(obj, number_of_bytes)
            bytes_left_to_read = uint32(number_of_bytes);
            bytes_left_in_cache = 1 + obj.SizeOfCurrentCache - obj.FilePointer;
            
            if bytes_left_in_cache >= bytes_left_to_read
                obj.FilePointer = obj.FilePointer + bytes_left_to_read;
            else
                
                while (bytes_left_to_read > 0) && (obj.MoreDataToRead)
                    bytes_left_in_cache = 1 + obj.SizeOfCurrentCache - obj.FilePointer;
                    next_bytes_read = min(bytes_left_in_cache, bytes_left_to_read);
                    bytes_left_to_read = bytes_left_to_read - next_bytes_read;
                    obj.FilePointer = obj.FilePointer + next_bytes_read;
                    if obj.FilePointer > obj.SizeOfCurrentCache
                        obj.ReadNextFileBlock;
                    end
                end
            
            end
        end
    end
    
    methods (Access = private)
        function data_bytes = ReadBytesFromCache(obj, number_of_bytes)
            bytes_left_to_read = uint32(number_of_bytes);
            bytes_left_in_cache = 1 + obj.SizeOfCurrentCache - obj.FilePointer;
            
            if bytes_left_in_cache >= bytes_left_to_read
                data_bytes = obj.FileCache(obj.FilePointer : obj.FilePointer + bytes_left_to_read - 1)';
                obj.FilePointer = obj.FilePointer + bytes_left_to_read;
            else
                data_bytes = zeros(1, number_of_bytes, 'uint8');
                data_bytes_pointer = uint32(1);
                
                while (bytes_left_to_read > 0) && (obj.MoreDataToRead)
                    bytes_left_in_cache = 1 + obj.SizeOfCurrentCache - obj.FilePointer;
                    next_bytes_read = min(bytes_left_in_cache, bytes_left_to_read);
                    data_bytes(data_bytes_pointer : data_bytes_pointer + next_bytes_read - 1) = obj.FileCache(obj.FilePointer : obj.FilePointer + next_bytes_read - 1);
                    data_bytes_pointer = data_bytes_pointer + next_bytes_read;
                    bytes_left_to_read = bytes_left_to_read - next_bytes_read;
                    obj.FilePointer = obj.FilePointer + next_bytes_read;
                    if obj.FilePointer > obj.SizeOfCurrentCache
                        obj.ReadNextFileBlock;
                    end
                end
            
                % If the end of the file has been reached, we may not have the full
                % number of bytes
                if bytes_left_to_read > 0
                    number_of_bytes_actually_read = number_of_bytes - bytes_left_to_read;
                    data_bytes = data_bytes(1 : number_of_bytes_actually_read);
                end
            end
        end
        
        function ReadNextFileBlock(obj)
            if obj.EofReached
                obj.FileCache = [];
            else
                obj.FileCache = fread(obj.FileId, obj.MaxFileCacheSize, 'uint8=>uint8');
                obj.SizeOfCurrentCache = uint32(numel(obj.FileCache));
                obj.FilePointer = uint32(1);
                if obj.SizeOfCurrentCache < obj.MaxFileCacheSize
                    obj.EofReached = true;
                    obj.Close;
                end
            end
        end
    end
end

