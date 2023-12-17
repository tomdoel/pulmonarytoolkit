classdef CoreReportingWithCache < CoreReportingInterface
    % CoreReportingWithCache. Provides error, message and progress reporting, with
    %     warnings and messages cached to prevent display of duplicates
    %
    %     CoreReportingWithCache is a wrapper around a CoreReporting object.
    %     Messages and warnings are cached using a CoreReportingWarningsCache and displayed
    %     at the end of the algorith. Duplicate messages and warnings are
    %     grouped together to prevent multiple messages appearing.
    %
    %     See CoreReportingIntertface.m for details of the methods this class
    %     implements.
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    properties (Access = protected)
        Reporting  % Handle to a CoreReporting object
    end
    
    properties (Access = private)
        WarningsCache
    end
    
    methods
        function obj = CoreReportingWithCache(reporting)
            if nargin > 0
                obj.Reporting = reporting;
            else
                obj.Reporting = CoreReportingDefault();
            end
            obj.WarningsCache = CoreReportingWarningsCache(obj);
        end
        
        function delete(obj)
            obj.ShowAndClearPendingMessages();
        end        
        
        function ClearProgressStack(obj)
            obj.Reporting.ClearProgressStack();
        end
        
        function PushProgress(obj)
            obj.Reporting.PushProgress();
        end
        
        function PopProgress(obj)
            obj.Reporting.PopProgress();
        end
        
        function Log(obj, message)
            obj.Reporting.Log(message);
        end
        
        function LogVerbose(obj, message)
            obj.Reporting.LogVerbose(message);
        end
        
        function ShowMessage(obj, identifier, message)
            obj.WarningsCache.AddPendingMessages(identifier, message);
        end
        
        function ShowMessageFromException(obj, identifier, message, ex)
            obj.Reporting.ShowMessageFromException(identifier, message, ex);
        end
        
        function ShowWarning(obj, identifier, message, supplementary_info)
            if nargin < 4
                supplementary_info = [];
            end
            obj.WarningsCache.AddPendingWarning(identifier, message, supplementary_info);
        end
        
        function Error(obj, identifier, message)
            obj.Reporting.Error(identifier, message);
        end
        
        function ErrorFromException(obj, identifier, message, ex)
            obj.Reporting.ErrorFromException(identifier, message, ex);
        end
                
        function ShowProgress(obj, text)
            obj.Reporting.ShowProgress(text);
        end
        
        function CompleteProgress(obj)
            obj.Reporting.CompleteProgress();
        end
        
        function UpdateProgressMessage(obj, text)
            obj.Reporting.UpdateProgressMessage(text);
        end
        
        function UpdateProgressValue(obj, progress_value)
            obj.Reporting.UpdateProgressValue(progress_value);
        end
         
        function UpdateProgressAndMessage(obj, progress_value, text)
            obj.Reporting.UpdateProgressAndMessage(progress_value, text);
        end
        
        function UpdateProgressStage(obj, progress_stage, num_stages)
            obj.Reporting.UpdateProgressStage(progress_stage, num_stages);
        end
        
        function cancelled = HasBeenCancelled(obj)
            cancelled = obj.Reporting.HasBeenCancelled();
        end
        
        function CheckForCancel(obj)
            obj.Reporting.CheckForCancel();
        end
        
        function ShowAndClearPendingMessages(obj)
            obj.WarningsCache.ShowAndClear();
            obj.Reporting.ShowAndClearPendingMessages();
        end
        
        function ShowCachedMessage(obj, identifier, message)
             obj.Reporting.ShowMessage(identifier, message);
        end
        
        function ShowCachedWarning(obj, identifier, message, supplementary_info)
             obj.Reporting.ShowWarning(identifier, message, supplementary_info);
        end
        
        function OpenPath(obj, file_path, message)
            obj.Reporting.OpenPath(file_path, message);
        end

    end
    
end