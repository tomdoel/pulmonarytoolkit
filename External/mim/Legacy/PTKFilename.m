classdef PTKFilename < CoreFilename
    % PTKFilename. A structure for holding a file name
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    methods
        function obj = PTKFilename(file_path, file_name)
            obj = obj@CoreFilename(file_path, file_name);
        end
    end
end

