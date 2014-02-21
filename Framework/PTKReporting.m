classdef PTKReporting < PTKReportingInterface
    % PTKReporting. Provides error, message and progress reporting.
    %
    %     PTKReporting. Implementation of PTKReportingInterface, which is used by
    %     the Pulmonary Toolkit for progress and error/message reporting. This
    %     implementation displays warnings and messages on the command window,
    %     and uses Matlab's error() command to process errors. Logging 
    %     information is writen to a log file. A PTKProcessDialog
    %     or PTKProgressPanel can be passed in for progress reporting, and a
    %     handle to a PTKViewerPanel can be passed in for obtaining gui
    %     orientation and marker information.
    %
    %     Usage
    %     -----
    %
    %     You should create a single PTKReporting object and pass it into all the
    %     Pulmonary Toolkit routines you use in order to provide error, warning,
    %     message and progress reporting during execution of routines.
    %
    %     If you are not writing a gui application but would like a standard
    %     pop-up progress dialog to appear while waiting for plugins to execute,
    %     consider creating a PTKReportingDefault object instead. Use PTKReporting
    %     if you want to specify your own progress dialog, or specify a gui
    %     viewing panel, or if you want no progress dialog at all.
    %
    %         reporting = PTKReporting(progress_dialog, viewing_panel);
    %
    %             progress_dialog - a PTKProgressDialog or PTKProgressPanel object
    %                 for displaying a progress bar. You can omit this argument
    %                 or replace it with [] if you are writing scripts to run 
    %                 in the background and do not want progress dialogs popping
    %                 up. Otherwise, you should create a PTKProgressDialog or
    %                 PTKProgressPanel, or else implement your own progress class
    %                 with the same interface as PTKProgressDialog and pass this
    %                 in.
    %
    %             viewing_panel - if you are implementing a gui using a
    %                 PTKViewingPanel, then you can provide the class handle here
    %                 so that plugins can query which orientation the gui is in
    %                 and obtain the current marker image. Otherwise leave this
    %                 argment blank.
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

    properties
        ProgressDialog  % Handle to a PTKProgressDialog or PTKProgressPanel
    end
    
    properties (Access = private)
        ViewingPanel    % Handle to gui viewing panel
        LogFileName     % Full path to log file
        
        % Stack for nested progress reporting
        ProgressStack
        CurrentProgressStackItem
        ParentProgressStackItem
        VerboseMode
    end
    
    methods
        function obj = PTKReporting(progress_dialog, viewing_panel, verbose_mode)
            if nargin > 0
                obj.ProgressDialog = progress_dialog;
            end
            if nargin > 1
                obj.ViewingPanel = viewing_panel;
            end
            if nargin > 2
                obj.VerboseMode = verbose_mode;
            else
                obj.VerboseMode = false;
            end
            obj.LogFileName = PTKDirectories.GetLogFilePath;
            
            obj.ClearProgressStack;
        end
        
        function Log(obj, message)
            [calling_function, ~] = PTKErrorUtilities.GetCallingFunction(2);
            
            obj.AppendToLogFile([calling_function ': ' message]);
        end
        
        function LogVerbose(obj, message)
            if obj.VerboseMode
                [calling_function, ~] = PTKErrorUtilities.GetCallingFunction(2);
                obj.AppendToLogFile([calling_function ': ' message]);
            end
        end
        
        function ShowMessage(obj, identifier, message)
            [calling_function, ~] = PTKErrorUtilities.GetCallingFunction(2);
            if isempty(calling_function)
                calling_function = 'Command Window';
            end
            disp(message);
            obj.AppendToLogFile([calling_function ': ' identifier ':' message]);
        end
        
        function ShowWarning(obj, identifier, message, supplementary_info)
            [calling_function, ~] = PTKErrorUtilities.GetCallingFunction(2);
            
            obj.AppendToLogFile([calling_function ': WARNING: ' identifier ':' message]);
            disp(['WARNING: ' message]);
            if ~isempty(supplementary_info)
                disp('Additional information on this warning:');
                disp(supplementary_info);
            end
            
        end
        
        function Error(obj, identifier, message)
            [calling_function, stack] = PTKErrorUtilities.GetCallingFunction(2);

            msgStruct = [];
            msgStruct.message = ['Error in function ' calling_function ': ' message];
            if PTKSoftwareInfo.IsErrorCancel(identifier) || PTKSoftwareInfo.IsErrorFileMissing(identifier)
                msgStruct.identifier = identifier;
            else
                msgStruct.identifier = [ 'PTKMain:' identifier];
            end
            msgStruct.stack = stack;
            obj.AppendToLogFile([calling_function ': ERROR: ' identifier ':' message]);
            error(msgStruct);
        end
        
        function ErrorFromException(obj, identifier, message, ex)
            [calling_function, stack] = PTKErrorUtilities.GetCallingFunction(2);

            msgStruct = [];
            msgStruct.message = ['Error in function ' calling_function ': ' message ' Exception message:' ex.message];
            msgStruct.identifier = [ 'PTKMain:' identifier];
            msgStruct.stack = stack;
            obj.AppendToLogFile([calling_function ': ERROR: ' identifier ':' message]);
            error(msgStruct);
        end
                
        function ShowProgress(obj, text)
            adjusted_text = obj.AdjustProgressText(text);
            
            if ~isempty(obj.ProgressDialog) && isvalid(obj.ProgressDialog)
                if nargin > 1
                    obj.ProgressDialog.SetProgressText(adjusted_text);
                else
                    obj.ProgressDialog.ProgressText();                    
                end
            end
        end
        
        function CompleteProgress(obj)
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.Complete;
            end
        end
        
        function UpdateProgressMessage(obj, text)
            adjusted_text = obj.AdjustProgressText(text);
            
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressText(adjusted_text);
            end
        end
        
        function UpdateProgressValue(obj, progress_value)
            adjusted_value = obj.AdjustProgressValue(progress_value, []);
            
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressValue(adjusted_value);
            end
            obj.CheckForCancel;
        end
        
        function UpdateProgressStage(obj, progress_stage, num_stages)
            progress_value = 100*progress_stage/num_stages;
            value_change = 100/num_stages;
            adjusted_value = obj.AdjustProgressValue(progress_value, value_change);
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressValue(adjusted_value);
            end
            obj.CheckForCancel;
        end
        
        function UpdateProgressAndMessage(obj, progress_value, text)
            adjusted_value = obj.AdjustProgressValue(progress_value, []);
            adjusted_text = obj.AdjustProgressText(text);
            
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressAndMessage(adjusted_value, adjusted_text);
            end
            obj.CheckForCancel;

        end
        
        function cancelled = HasBeenCancelled(obj)
            if ~isempty(obj.ProgressDialog)
                cancelled = obj.ProgressDialog.CancelClicked;
            else
                cancelled = false;
            end
        end
        
        function CheckForCancel(obj)
            if obj.HasBeenCancelled
                obj.Error(PTKSoftwareInfo.CancelErrorId, 'User cancelled');
            end
        end
        
        function ChangeViewingPosition(obj, coordinates)
            if ~isempty(obj.ViewingPanel)
                obj.ViewingPanel.SliceNumber = coordinates;
            end
        end
        
        function ChangeViewingOrientation(obj, orientation)
            if ~isempty(obj.ViewingPanel)
                obj.ViewingPanel.Orientation = orientation;
            end
        end
        
        function orientation = GetOrientation(obj)
            if ~isempty(obj.ViewingPanel)
                orientation = obj.ViewingPanel.Orientation;
            else
                orientation = 1;
            end
        end
        
        function marker_image = GetMarkerImage(obj)
            if isempty(obj.ViewingPanel)
                marker_image = [];
            else
                marker_image = obj.ViewingPanel.MarkerPointManager.GetMarkerImage;
            end
        end

        function UpdateOverlayImage(obj, new_image)
            if ~isempty(obj.ViewingPanel)
                obj.ViewingPanel.OverlayImage.ChangeSubImage(new_image);
                obj.ViewingPanel.OverlayImage.ImageType = new_image.ImageType;
            end
        end
        
        function UpdateOverlaySubImage(obj, new_image)
            if ~isempty(obj.ViewingPanel)
                obj.ViewingPanel.OverlayImage.ChangeSubImage(new_image);
            end
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
        
        function ClearProgressStack(obj)
            obj.ProgressStack = PTKProgressStackItem.empty(0);
            obj.CurrentProgressStackItem = PTKProgressStackItem('', 0, 100);
            obj.ParentProgressStackItem = PTKProgressStackItem('', 0, 100);
        end
        
        function ShowAndClearPendingMessages(obj)
        end
        
        function SetViewerPanel(obj, viewer_panel)
            obj.ViewingPanel = viewer_panel;
        end
        
    end
    
    methods (Access = private)
        function AppendToLogFile(obj, message)
            file_id = fopen(obj.LogFileName, 'at');
            message = [datestr(now) ': ' message];
            fprintf(file_id, '%s\n', message);
            fclose(file_id);
        end
        
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
        
        function SetValueChange(obj, value_change)
            value = obj.CurrentProgressStackItem.LastProgressValue;
            scale = (obj.ParentProgressStackItem.MaxPosition - obj.ParentProgressStackItem.MinPosition)/100;
            adjusted_value = obj.ParentProgressStackItem.MinPosition + scale*value;
            obj.CurrentProgressStackItem.MinPosition = adjusted_value;
            if value_change > 0
                obj.CurrentProgressStackItem.MaxPosition = adjusted_value + scale*value_change;
            end
        end
        
    end
end

