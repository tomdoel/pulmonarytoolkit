classdef PTKAdmin < MimScript
    % PTKAdmin. Script for running functions from the PTK object
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        InterfaceVersion = '1'
        Version = '1'
        Category= 'Admin'
    end
    
    methods (Static)
        function output = RunScript(ptk_obj, reporting, varargin)
            ptk_obj.(varargin{1})(varargin{2:end});
            output = [];
        end
    end
end