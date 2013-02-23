classdef MockReporting < PTKReportingInterface
    % MockReporting. Part of the PTK test framework
    %
    % This class is used in tests in place of an object implementing the
    % PTKReportingInterface. It allows expected calls to be verified, while
    % maintaining some of the expected behaviour of a Reporting object.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        Expectations
    end
    
    methods
        function obj = MockReporting
            obj.Expectations = PTKTestExpectationChecker;
        end
        
        function AddExpectation(obj, function_name, parameters)
            obj.Expectations.AddExpectation(function_name, parameters);
        end
        
        function Log(obj, message)
        end
        
        function ShowMessage(obj, identifier, message)
        end
        
        function ShowWarning(obj, identifier, message, supplementary_info)
        end
        
        function Error(obj, identifier, message)
            obj.Expectations.CheckExpectation(identifier);
            throw(PTKTestException);
        end
        
        function ErrorFromException(obj, identifier, message, ex)
            throw(PTKTestException);
        end

        function ShowProgress(obj, text)
        end
        
        function CompleteProgress(obj)
        end
        
        function UpdateProgressMessage(obj, text)
        end
        
        function UpdateProgressValue(obj, progress_value)
        end
         
        function UpdateProgressStage(obj, progress_stage, num_stages)
        end
        
        function UpdateProgressAndMessage(obj, progress_value, text)
        end
        
        function cancelled = HasBeenCancelled(obj)
        end
        
        function CheckForCancel(obj)
        end

        function ChangeViewingPosition(obj, coordinates)
        end
        
        function orientation = GetOrientation(obj)
        end
        
        function marker_image = GetMarkerImage(obj)
        end
    end
end

