classdef PTKTestExpectationChecker < handle
    % PTKTestExpectationChecker. Part of the PTK test framework
    %
    % This class is used to stores and verify a list of expected behaviour for a
    % mock class for use in tests.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    
    properties
        ExpectationList
    end
    
    methods
        function obj = PTKTestExpectationChecker
            obj.ExpectationList = PTKTestExpectation.empty;
        end
    
        function AddExpectation(obj, function_name, parameters)
            obj.ExpectationList(end+1) = PTKTestExpectation(function_name, parameters);
        end
        
        function CheckExpectation(obj, parameters)
            current_expectation = obj.ExpectationList(1);
            obj.ExpectationList(1) = [];
            
            [calling_function, stack] = PTKErrorUtilities.GetCallingFunction(2);
            if ~strcmp(current_expectation.MethodName, calling_function)
                PTKErrorUtilities.ThrowException('PTKTestExpectationChecker:WrongCallingFunction', ...
                    ['Test failure: expected call to ' current_expectation.MethodName ' but actual call was to ' calling_function]);
            end
            
            if parameters ~= current_expectation.Parameters
                PTKErrorUtilities.ThrowException('PTKTestExpectationChecker:WrongParameter', ...
                    ['Test failure: parameters not as expected. Expected: ' char(current_expectation.Parameters) ' but actually ' char(parametrs)]);
            end
            
        end
    end
    
end

