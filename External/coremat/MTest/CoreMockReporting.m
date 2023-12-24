classdef CoreMockReporting < CoreReportingInterface
    % Mock Reporting class for MTest unit tests
    %
    % This class is used in tests in place of an object implementing the
    % CoreReportingInterface. It allows expected calls to be verified, while
    % maintaining some of the expected behaviour of a Reporting object.
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    properties
        Expectations
    end
    
    methods
        function obj = CoreMockReporting
            obj.Expectations = CoreTestExpectationChecker;
        end
        
        function AddExpectation(obj, functionName, parameters)
            obj.Expectations.AddExpectation(functionName, parameters);
        end
        
        function Log(obj, message)
        end
        
        function LogVerbose(obj, message)
        end
        
        function ShowMessage(obj, identifier, message)
        end
        
        function ShowWarning(obj, identifier, message, supplementaryInfo)
        end
        
        function Error(obj, identifier, message)
            obj.Expectations.CheckExpectation(identifier);
            throw(CoreTestException);
        end
        
        function ErrorFromException(obj, identifier, message, ex)
            throw(CoreTestException);
        end

        function ShowProgress(obj, text)
        end
        
        function CompleteProgress(obj)
        end
        
        function UpdateProgressMessage(obj, text)
        end
        
        function UpdateProgressValue(obj, progressValue)
        end
         
        function UpdateProgressStage(obj, progressStage, numStages)
        end
        
        function UpdateProgressAndMessage(obj, progressValue, text)
        end
        
        function cancelled = HasBeenCancelled(obj)
        end
        
        function CheckForCancel(obj)
        end

        function PushProgress(obj)
        end

        function PopProgress(obj)
        end
        
        function ClearProgressStack(obj)
        end
        
        function ShowAndClearPendingMessages(obj)
        end
    end
end

