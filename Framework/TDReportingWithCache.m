classdef TDReportingWithCache < TDReportingInterface
    % TDReportingWithCache. Provides error, message and progress reporting, with
    %     warnings and messages cached to prevent display of duplicates
    %
    %     TDReportingWithCache is a wrapper around a TDReporting object.
    %     Messages and warnings are cached using a TDReportingWarningsCache and displayed
    %     at the end of the algorith. Duplicate messages and warnings are
    %     grouped together to prevent multiple messages appearing.
    %
    %     See TDReportingIntertface.m for details of the methods this class
    %     implements.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties (Access = private)
        Reporting  % Handle to a TDReporting object
        WarningsCache
    end
    
    methods
        function obj = TDReportingWithCache(reporting)
            if nargin > 0
                obj.Reporting = reporting;
            else
                obj.Reporting = TDReportingDefault;
            end
            obj.WarningsCache = TDReportingWarningsCache(obj);
        end
        
        function delete(obj)
            obj.ShowAndClear;
        end        
        
        function Log(obj, message)
            obj.Reporting.Log(message);
        end
        
        function ShowMessage(obj, identifier, message)
            obj.WarningsCache.AddPendingMessages(identifier, message);
        end
        
        function ShowWarning(obj, identifier, message, supplementary_info)
            obj.WarningsCache.AddPendingWarning(identifier, message, supplementary_info);
        end
        
        
        function Error(obj, identifier, message)
            obj.Reporting.Error(identifier, message);
        end
        
        function ErrorFromException(obj, identifier, message, ex)
            obj.Reporting.Error(identifier, message, ex);
        end
                
        function ShowProgress(obj, text)
            obj.Reporting.ShowProgress(text);
        end
        
        function CompleteProgress(obj)
            obj.Reporting.CompleteProgress;
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
        
        function cancelled = HasBeenCancelled(obj)
            cancelled = obj.Reporting.HasBeenCancelled;
        end
        
        function CheckForCancel(obj)
            obj.Reporting.CheckForCancel;
        end
        
        function ChangeViewingPosition(obj, coordinates)
            obj.Reporting.ChangeViewingPosition(coordinates);
        end
        
        function orientation = GetOrientation(obj)
            orientation = obj.Reporting.GetOrientation;
        end
        
        function marker_image = GetMarkerImage(obj)
            marker_image = obj.Reporting.GetMarkerImage;
        end

        function UpdateOverlayImage(obj, new_image)
            obj.Reporting.UpdateOverlayImage(new_image);
        end
        
        function ShowAndClear(obj)
            obj.WarningsCache.ShowAndClear;
        end
        
        function ShowCachedMessage(obj, identifier, message)
             obj.Reporting.ShowMessage(identifier, message);
        end
        
        function ShowCachedWarning(obj, identifier, message, supplementary_info)
             obj.Reporting.ShowWarning(identifier, message, supplementary_info);
        end
    end
end