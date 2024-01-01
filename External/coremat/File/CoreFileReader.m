classdef CoreFileReader < CoreBaseClass
    % A helper class to assist with parsing a text file
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    properties (Access = private)
        FileId
        Reporting
    end
    
    methods
        function obj = CoreFileReader(file_path, file_name, transfer_syntax, reporting)
            obj.Reporting = reporting;
            full_file_name = fullfile(file_path, file_name);

            if isempty(transfer_syntax)
                file_id = fopen(full_file_name, 'r');
            else
                switch transfer_syntax.Endian
                    case CoreEndian.BigEndian
                        file_encoding = 'b';
                    case CoreEndian.LittleEndian
                        file_encoding = 'l';
                    otherwise
                        error('Unknown file encoding');
                end
                
                switch transfer_syntax.CharacterEncoding
                    case CoreCharacterEncoding.UTF8
                        character_encoding = 'UTF-8';
                    otherwise
                        error('Unknown character encoding');
                end
                
                file_id = fopen(full_file_name, 'r', file_encoding, character_encoding);
            end

            if (file_id == -1)
                reporting.Error('CoreFileReader:CannotOpenFile', ['Unable to open file ' full_file_name]);
            else
                obj.FileId = file_id;
            end

        end
        
        function delete(obj)
            obj.Close;
        end
        
        function data = ReadWords(obj, data_type, number_of_words)
            [data, count] = fread(obj.FileId, [1, number_of_words], data_type);
            if count ~= number_of_words
                obj.Reporting.Error('CoreFileReader:ReadBeyondEndOfFile', ['Tried to read beyond the end of file ']);
            end
            if strcmp(data_type, 'char')
                data = char(data);
            end
        end
        
        function data = ReadData(obj, data_type, number_of_bytes)
            
            if strcmp(data_type, 'char')
                number_of_words = number_of_bytes;
            else
                bytes_in_type = CoreSystemUtilities.GetBytesInType(data_type);
                number_of_words = ceil(number_of_bytes/bytes_in_type);
            end
            
            [data, count] = fread(obj.FileId, [1, number_of_words], data_type);
            if count ~= number_of_words
                obj.Reporting.Error('CoreFileReader:ReadBeyondEndOfFile', ['Tried to read beyond the end of file ']);
            end
            if strcmp(data_type, 'char')
                data = char(data);
            end
        end
        
        function data = ReadString(obj, number_of_bytes)
            data = fread(obj.FileId, [1, number_of_bytes], '*char');
        end
        
        function Close(obj)
            if ~isempty(obj.FileId)
                fclose(obj.FileId);
                obj.FileId = [];
            end
        end
        
        function more_data = MoreDataToRead(obj)
            more_data = ~feof(obj.FileId);
        end
        
        function Skip(obj, number_of_bytes)
            fseek(obj.FileId, 'cof', number_of_bytes);
        end
        
        function GoToFilePosition(obj, bytes_from_beginning)
            status = fseek(obj.FileId, bytes_from_beginning, 'bof');
            if status == -1
                obj.Reporting.Error('CoreFileReader:Requested position is beyond the end of the file.');
            end
        end

    end
end