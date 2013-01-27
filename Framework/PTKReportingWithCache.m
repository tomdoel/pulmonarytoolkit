classdef PTKReportingWithCache < PTKReportingInterface
    % PTKReportingWithCache. Provides error, message and progress reporting, with
    %     warnings and messages cached to prevent display of duplicates
    %
    %     PTKReportingWithCache is a wrapper around a PTKReporting object.
    %     Messages and warnings are cached using a PTKReportingWarningsCache and displayed
    %     at the end of the algorith. Duplicate messages and warnings are
    %     grouped together to prevent multiple messages appearing.
    %
    %     See PTKReportingIntertface.m for details of the methods this class
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
        Reporting  % Handle to a PTKReporting object
        WarningsCache
        ProgressStack
        CurrentProgressStackItem
        ParentProgressStackItem
    end
    
    methods
        function obj = PTKReportingWithCache(reporting)
            if nargin > 0
                obj.Reporting = reporting;
            else
                obj.Reporting = PTKReportingDefault;
            end
            obj.WarningsCache = PTKReportingWarningsCache(obj);
            obj.ClearStack;
        end
        
        function delete(obj)
            obj.ShowAndClear;
        end        
        
        function ClearStack(obj)
            obj.ProgressStack = PTKProgressStackItem.empty(0);
            obj.CurrentProgressStackItem = PTKProgressStackItem('', 0, 100);
            obj.ParentProgressStackItem = PTKProgressStackItem('', 0, 100);
        end
        
        function PushProgress(obj)
            obj.ProgressStack(end + 1) = obj.ParentProgressStackItem;
            obj.ParentProgressStackItem = obj.CurrentProgressStackItem;
            obj.CurrentProgressStackItem = PTKProgressStackItem('', obj.ParentProgressStackItem.MinPosition, obj.ParentProgressStackItem.MaxPosition);
        end
        
        function PopProgress(obj)
            obj.CurrentProgressStackItem = obj.ParentProgressStackItem;
            obj.ParentProgressStackItem = obj.ProgressStack(end);
            obj.ProgressStack(end) = [];
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
            obj.Reporting.ShowProgress(obj.AdjustProgressText(text));
        end
        
        function CompleteProgress(obj)
            obj.Reporting.CompleteProgress;
        end
        
        function UpdateProgressMessage(obj, text)
            obj.Reporting.UpdateProgressMessage(obj.AdjustProgressText(text));
        end
        
        function UpdateProgressValue(obj, progress_value)
            obj.Reporting.UpdateProgressValue(obj.AdjustProgressValue(progress_value, []));
        end
         
        function UpdateProgressAndMessage(obj, progress_value, text)
            obj.Reporting.UpdateProgressAndMessage(obj.AdjustProgressValue(progress_value, []), obj.AdjustProgressText(text));
        end
        
        function UpdateProgressStage(obj, progress_stage, num_stages)
            progress_value = 100*progress_stage/num_stages;
            value_change = 100/num_stages;
            obj.Reporting.UpdateProgressValue(obj.AdjustProgressValue(progress_value, value_change));
%             obj.Reporting.UpdateProgressStage(progress_stage, num_stages);
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
        
        function UpdateOverlaySubImage(obj, new_image)
            obj.Reporting.UpdateOverlaySubImage(new_image);
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
    
    methods (Access = private)
        function adjusted_text = AdjustProgressText(obj, text)
            adjusted_text = text;
            obj.CurrentProgressStackItem.ProgressText = text;
        end
        
        function adjusted_value = AdjustProgressValue(obj, value, value_change)
            if isempty(value_change)
                value_change = value - obj.CurrentProgressStackItem.LastProgressValue;
            end
            obj.CurrentProgressStackItem.LastProgressValue = value;
            
            scale = (obj.ParentProgressStackItem.MaxPosition - obj.ParentProgressStackItem.MinPosition)/100;
            adjusted_value = obj.ParentProgressStackItem.MinPosition + scale*value;
            obj.CurrentProgressStackItem.MinPosition = adjusted_value;
            if value_change > 0
                obj.CurrentProgressStackItem.MaxPosition = adjusted_value + scale*value_change;
            end
        end        
    end
end