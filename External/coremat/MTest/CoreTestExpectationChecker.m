classdef CoreTestExpectationChecker < handle
    % CoreTestExpectationChecker. Part of the MTest unit test framework
    %
    % This class is used to stores and verify a list of expected behaviour for a
    % mock class for use in tests.
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    
    properties
        ExpectationList
    end
    
    methods
        function obj = CoreTestExpectationChecker
            obj.ExpectationList = CoreTestExpectation.empty;
        end
    
        function AddExpectation(obj, functionName, parameters)
            obj.ExpectationList(end+1) = CoreTestExpectation(functionName, parameters);
        end
        
        function CheckExpectation(obj, parameters)
            currentExpectation = obj.ExpectationList(1);
            obj.ExpectationList(1) = [];
            
            [callingFunction, stack] = CoreErrorUtilities.GetCallingFunction(2);
            if ~strcmp(currentExpectation.MethodName, callingFunction)
                CoreErrorUtilities.ThrowException('CoreTestExpectationChecker:WrongCallingFunction', ...
                    ['Test failure: expected call to ' currentExpectation.MethodName ' but actual call was to ' callingFunction]);
            end
            
            if parameters ~= currentExpectation.Parameters
                CoreErrorUtilities.ThrowException('CoreTestExpectationChecker:WrongParameter', ...
                    ['Test failure: parameters not as expected. Expected: ' char(currentExpectation.Parameters) ' but actually ' char(parametrs)]);
            end
            
        end
    end
    
end

