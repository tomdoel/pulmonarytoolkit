classdef PTKFileReader < handle
    % PTKFileReader. A helper class to assist with parsing a text file
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        FileText
        FileId
    end
    
    methods
        function obj = PTKFileReader(file_path, file_name, reporting)
            full_file_name = fullfile(file_path, file_name);
            file_id = fopen(full_file_name, 'rt');
            if (file_id == -1)
                reporting.Error('PTKFileReader:CannotOpenFile', ['Unable to open file ' full_file_name]);
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
                next_line = strtrim(next_line);
            end
        end
        
        function data = ReadData(obj, format_string, num_points)
            data = textscan(obj.FileId, format_string, num_points);
        end
    end
end

