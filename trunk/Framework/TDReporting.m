classdef TDReporting < TDReportingInterface
    % TDReporting. Provides error, message and progress reporting.
    %
    %     TDReporting. Implementation of TDReportingInterface, which is used by
    %     the Pulmonary Toolkit for progress and error/message reporting. This
    %     implementation displays warnings and messages on the command window,
    %     and uses Matlab's error() command to process errors. Logging 
    %     information is writen to a log file. A TDProcessDialog
    %     or TDProgressPanel can be passed in for progress reporting, and a
    %     handle to a TDViewerPanel can be passed in for obtaining gui
    %     orientation and marker information.
    %
    %     Usage
    %     -----
    %
    %     You should create a single TDReporting object and pass it into all the
    %     Pulmonary Toolkit routines you use in order to provide error, warning,
    %     message and progress reporting during execution of routines.
    %
    %     If you are not writing a gui application but would like a standard
    %     pop-up progress dialog to appear while waiting for plugins to execute,
    %     consider creating a TDReportingDefault object instead. Use TDReporting
    %     if you want to specify your own progress dialog, or specify a gui
    %     viewing panel, or if you want no progress dialog at all.
    %
    %         reporting = TDReporting(progress_dialog, viewing_panel);
    %
    %             progress_dialog - a TDProgressDialog or TDProgressPanel object
    %                 for displaying a progress bar. You can omit this argument
    %                 or replace it with [] if you are writing scripts to run 
    %                 in the background and do not want progress dialogs popping
    %                 up. Otherwise, you should create a TDProgressDialog or
    %                 TDProgressPanel, or else implement your own progress class
    %                 with the same interface as TDProgressDialog and pass this
    %                 in.
    %
    %             viewing_panel - if you are implementing a gui using a
    %                 TDViewingPanel, then you can provide the class handle here
    %                 so that plugins can query which orientation the gui is in
    %                 and obtain the current marker image. Otherwise leave this
    %                 argment blank.
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

    properties
        ProgressDialog  % Handle to a TDProgressDialog or TDProgressPanel
    end
    
    properties (Access = private)
        ViewingPanel    % Handle to gui viewing panel
        LogFileName     % Full path to log file
    end
    
    methods
        function obj = TDReporting(progress_dialog, viewing_panel)
            if nargin > 0
                obj.ProgressDialog = progress_dialog;
            end
            if nargin > 1
                obj.ViewingPanel = viewing_panel;
            end
            settings_folder = TDSoftwareInfo.GetApplicationDirectoryAndCreateIfNecessary;
            log_file_name = TDSoftwareInfo.LogFileName;
            obj.LogFileName = fullfile(settings_folder, log_file_name);
        end
        
        function Log(obj, message)
            [calling_function, ~] = TDErrorUtilities.GetCallingFunction(2);
            
            obj.AppendToLogFile([calling_function ': ' message]);
        end
        
        function ShowMessage(obj, identifier, message)
            [calling_function, ~] = TDErrorUtilities.GetCallingFunction(2);
            disp(message);
            obj.AppendToLogFile([calling_function ': ' identifier ':' message]);
        end
        
        function ShowWarning(obj, identifier, message, supplementary_info)
            [calling_function, ~] = TDErrorUtilities.GetCallingFunction(2);
            
            obj.AppendToLogFile([calling_function ': WARNING: ' identifier ':' message]);
            disp(['WARNING: ' message]);
            if ~isempty(supplementary_info)
                disp('Additional information on this warning:');
                disp(supplementary_info);
            end
            
        end
        
        function Error(obj, identifier, message)
            [calling_function, stack] = TDErrorUtilities.GetCallingFunction(2);

            msgStruct = [];
            msgStruct.message = ['Error in function ' calling_function ': ' message];
            if TDSoftwareInfo.IsErrorCancel(identifier)
                msgStruct.identifier = identifier;
            else
                msgStruct.identifier = [ 'TDPTK:' identifier];
            end
            msgStruct.stack = stack;
            obj.AppendToLogFile([calling_function ': ERROR: ' identifier ':' message]);
            error(msgStruct);
        end
        
        function ErrorFromException(obj, identifier, message, ex)
            [calling_function, stack] = TDErrorUtilities.GetCallingFunction(2);

            msgStruct = [];
            msgStruct.message = ['Error in function ' calling_function ': ' message ' Exception message:' ex.message];
            msgStruct.identifier = [ 'TDPTK:' identifier];
            msgStruct.stack = stack;
            obj.AppendToLogFile([calling_function ': ERROR: ' identifier ':' message]);
            error(msgStruct);
        end
                
        function ShowProgress(obj, text)
            if ~isempty(obj.ProgressDialog)
                if nargin > 1
                    obj.ProgressDialog.SetProgressText(text);
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
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressText(text);
            end
        end
        
        function UpdateProgressValue(obj, progress_value)
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressValue(progress_value);
            end
            obj.CheckForCancel;
        end
         
        function UpdateProgressAndMessage(obj, progress_value, text)
            if ~isempty(obj.ProgressDialog)
                obj.ProgressDialog.SetProgressAndMessage(progress_value, text);
            end
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
                obj.Error(TDSoftwareInfo.CancelErrorId, 'User cancelled');
            end
        end
        
        function ChangeViewingPosition(obj, coordinates)
            if ~isempty(obj.ViewingPanel)
                obj.ViewingPanel.SliceNumber = coordinates;
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
                obj.ViewingPanel.OverlayImage.ChangeRawImage(new_image);
            end
        end
    end
    
    methods (Access = private)
        function AppendToLogFile(obj, message)
            file_id = fopen(obj.LogFileName, 'at');
            message = [datestr(now) ': ' message];
            fprintf(file_id, '%s\n', message);
            fclose(file_id);
        end
    end
end

