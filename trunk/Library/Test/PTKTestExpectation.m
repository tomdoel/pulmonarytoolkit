classdef PTKTestExpectation
    % PTKTestExpectation. Part of the PTK test framework
    %
    % This class is used by PTKTestExpectationChecker to store the expected
    % parameters of a function call, so that 
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
        
    properties
        MethodName
        Parameters
    end
    
    methods
        function obj = PTKTestExpectation(method_name, parameters)
            obj.MethodName = method_name;
            obj.Parameters = parameters;
        end
    end
    
end

