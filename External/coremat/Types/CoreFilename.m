classdef CoreFilename
    % CoreFilename. A structure for holding a file name
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        Path
        Name
    end
    
    methods
        function obj = CoreFilename(file_path, file_name)
            if nargin > 0
                obj.Path = file_path;
                obj.Name = file_name;
            end
        end
        
        function file_name = FullFile(obj)
            if isempty(obj.Path)
                file_name = obj.Name;
            elseif isempty(obj.Name)
                file_name = obj.Path;
            else
                file_name = fullfile(obj.Path, obj.Name);
            end
        end
    end
end

