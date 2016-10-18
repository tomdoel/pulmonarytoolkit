classdef CoreReporting < CoreReportingInterface
    % CoreReporting. Provides error, message and progress reporting.
    %
    %     CoreReporting. Implementation of CoreReportingInterface, which is used by
    %     CoreMat and other libraries for progress and error/message reporting. This
    %     implementation displays warnings and messages on the command window,
    %     and uses Matlab's error() command to process errors. Logging 
    %     information is writen to a log file. An object which implements
    %     the CoreProgressInterface can be passed in for progress reporting.
    % 
    %     Usage
    %     -----
    %
    %     You should create a single CoreReporting object and pass it into all the
    %     CoreMat routines you use in order to provide error, warning,
    %     message and progress reporting during execution of routines.
    %
    %     If you are not writing a gui application but would like a standard
    %     pop-up progress dialog to appear while waiting for plugins to execute,
    %     consider creating a CoreReportingDefault object instead. Use CoreReporting
    %     if you want to specify your own progress dialog, or specify a gui
    %     viewing panel, or if you want no progress dialog at all.
    %
    %         reporting = CoreReporting(progress_dialog, viewing_panel);
    %
    %             progress_dialog - a CoreProgressInterface object such as
    %                 a CoreProgressDialog for displaying a progress bar. You can omit this argument
    %                 or replace it with [] if you are writing scripts to run 
    %                 in the background and do not want progress dialogs popping
    %                 up. Otherwise, you should create a CoreProgressDialog
    %                 or else implement your own progress class if you want
    %                 custom behaviour.
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

    properties (Constant)
        CancelErrorId = 'CoreReporting:UserCancel'
    end
    
    properties
        ProgressDialog  % Handle to a CoreProgressInterface object
    end
    
    properties (Access = private)
        LogFileName     % Full path to log file
        
        % Stack for nested progress reporting
        ProgressStack
        CurrentProgressStackItem
        ParentProgressStackItem
        VerboseMode
    end
    
    methods
        function obj = CoreReporting(progress_dialog, verbose_mode, log_file_name)
            if nargin > 0
                obj.ProgressDialog = progress_dialog;
            end
            if nargin > 1
                obj.VerboseMode = verbose_mode;
            else
                obj.VerboseMode = false;
            end
            if nargin > 2
                obj.LogFileName = log_file_name;
            else
                obj.LogFileName = fullfile(CoreDiskUtilities.GetUserDirectory, 'corereporting.log');
            end
            
            obj.ClearProgressStack;
        end
        
        function Log(obj, message)
            [calling_function, ~] = CoreErrorUtilities.GetCallingFunction(2);
            
            obj.AppendToLogFile([calling_function ': ' message]);
        end
        
        function LogVerbose(obj, message)
            if obj.VerboseMode
                [calling_function, ~] = CoreErrorUtilities.GetCallingFunction(2);
                obj.AppendToLogFile([calling_function ': ' message]);
            end
        end
        
        function ShowMessage(obj, identifier, message)
            [calling_function, ~] = CoreErrorUtilities.GetCallingFunction(2);
            if isempty(calling_function)
                calling_function = 'Command Window';
            end
            disp(message);
            obj.AppendToLogFile([calling_function ': ' identifier ':' message]);
        end
        
        function ShowWarning(obj, identifier, message, supplementary_info)
            [calling_function, ~] = CoreErrorUtilities.GetCallingFunction(2);
            
            obj.AppendToLogFile([calling_function ': WARNING: ' identifier ':' message]);
            disp(['WARNING: ' message]);
            if nargin > 3 && ~isempty(supplementary_info)
                disp('Additional information on this warning:');
                disp(supplementary_info);
            end
            
        end
        
        function Error(obj, identifier, message)
            [calling_function, stack] = CoreErrorUtilities.GetCallingFunction(2);
            
            if ischar(calling_function) && length(calling_function) >= 13 && strcmp(calling_function(1:13), 'CoreReporting')
                [calling_function, stack] = CoreErrorUtilities.GetCallingFunction(3);
            end

            msgStruct = [];
            msgStruct.message = ['Error in function ' calling_function ': ' message];
            msgStruct.identifier = identifier;
            msgStruct.stack = stack;
            obj.AppendToLogFile([calling_function ': ERROR: ' identifier ':' message]);
            error(msgStruct);
        end
        
        function ErrorFromException(obj, identifier, message, ex)
            [calling_function, stack] = CoreErrorUtilities.GetCallingFunction(2);

            msgStruct = [];
            msgStruct.message = ['Error in function ' calling_function ': ' message ' Exception message:' ex.message];
            msgStruct.identifier = identifier;
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
                obj.CurrentProgressStackItem.Visible = true;
            end
        end
        
        function CompleteProgress(obj)
            if ~isempty(obj.ProgressDialog)
                if isempty(obj.ProgressStack) || ~obj.ParentProgressStackItem.Visible
                    obj.ProgressDialog.Complete;
                    obj.CurrentProgressStackItem.Visible = false;
                end
            end
        end
        
        function UpdateProgressMessage(obj, text)
            adjusted_text = obj.AdjustProgressText(text);
            
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressText(adjusted_text);
                obj.CurrentProgressStackItem.Visible = true;
            end
        end
        
        function UpdateProgressValue(obj, progress_value)
            adjusted_value = obj.AdjustProgressValue(progress_value, []);
            
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressValue(adjusted_value);
                obj.CurrentProgressStackItem.Visible = true;
            end
            obj.CheckForCancel;
        end
        
        function UpdateProgressStage(obj, progress_stage, num_stages)
            progress_value = 100*progress_stage/num_stages;
            value_change = 100/num_stages;
            adjusted_value = obj.AdjustProgressValue(progress_value, value_change);
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressValue(adjusted_value);
                obj.CurrentProgressStackItem.Visible = true;
            end
            obj.CheckForCancel;
        end
        
        function UpdateProgressAndMessage(obj, progress_value, text)
            adjusted_value = obj.AdjustProgressValue(progress_value, []);
            adjusted_text = obj.AdjustProgressText(text);
            
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressAndMessage(adjusted_value, adjusted_text);
                obj.CurrentProgressStackItem.Visible = true;
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
                obj.Error(CoreReporting.CancelErrorId, 'User cancelled');
            end
        end
        
        function PushProgress(obj)
            obj.ProgressStack(end + 1) = obj.ParentProgressStackItem;
            obj.ParentProgressStackItem = obj.CurrentProgressStackItem;
            obj.CurrentProgressStackItem = CoreProgressStackItem('', obj.ParentProgressStackItem.MinPosition, obj.ParentProgressStackItem.MaxPosition);
            obj.CurrentProgressStackItem.Visible = obj.ParentProgressStackItem.Visible;

        end
            
        function PopProgress(obj)
            obj.CurrentProgressStackItem = obj.ParentProgressStackItem;
            obj.ParentProgressStackItem = obj.ProgressStack(end);
            obj.ProgressStack(end) = [];
        end
        
        function ClearProgressStack(obj)
            obj.ProgressStack = CoreProgressStackItem.empty(0);
            obj.CurrentProgressStackItem = CoreProgressStackItem('', 0, 100);
            obj.ParentProgressStackItem = CoreProgressStackItem('', 0, 100);
        end
        
        function ShowAndClearPendingMessages(obj)
        end
        
        function OpenPath(obj, file_path, message)
            disp([message, ': ', file_path]);
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

