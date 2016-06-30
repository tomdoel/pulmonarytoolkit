classdef CoreTextFileWriter < CoreBaseClass
    % CoreTextFileWriter. A helper class to assist with writing a text file
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    properties
        FileText
        FileId
    end
    
    methods
        function obj = CoreTextFileWriter(file_path, file_name, reporting)
            full_file_name = fullfile(file_path, file_name);
            file_id = fopen(full_file_name, 'w');
            
            if (file_id == -1)
                reporting.Error('CoreTextFileWriter:CannotOpenFile', ['Unable to open file ' full_file_name]);
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
        
        function WriteLine(obj, text)
            fprintf(obj.FileId, [strrep(text, '%', '%%') '\r\n']);
        end
        
        function is_eof = Eof(obj)
            is_eof = isempty(obj.FileId);
        end
    end
end

