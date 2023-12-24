classdef CoreTestExpectation
    % Part of the MTest unit test framework
    %
    % This class is used by CoreTestExpectationChecker to store the expected
    % parameters of a function call, so that 
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
        
    properties
        MethodName
        Parameters
    end
    
    methods
        function obj = CoreTestExpectation(methodName, parameters)
            obj.MethodName = methodName;
            obj.Parameters = parameters;
        end
    end
    
end

