classdef PTKFilename < CoreFilename
    % A structure for holding a file name. Equivalent to CoreFilename
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %        
    
    methods
        function obj = PTKFilename(file_path, file_name)
            obj = obj@CoreFilename(file_path, file_name);
        end
    end
end

