classdef CoreTextFileReader < CoreBaseClass
    % A helper class to assist with parsing a text file
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    properties
        FileText
        FileId
    end
    
    methods
        function obj = CoreTextFileReader(file_path, file_name, reporting)
            full_file_name = fullfile(file_path, file_name);
            file_id = fopen(full_file_name, 'rt');
            if (file_id == -1)
                reporting.Error('CoreTextFileReader:CannotOpenFile', ['Unable to open file ' full_file_name]);
            else
                obj.FileId = file_id;
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
        
        function next_line = NextLine(obj)
            next_line = [];
            while isempty(next_line)
                next_line = fgetl(obj.FileId);
                if next_line == -1
                    next_line = [];
                    obj.Close;
                    return;
                end
                next_line = strtrim(next_line);
            end
        end
        
        function data = ReadData(obj, format_string, num_points)
            data = textscan(obj.FileId, format_string, num_points);
        end
        
        function is_eof = Eof(obj)
            is_eof = isempty(obj.FileId);
        end
    end
end

