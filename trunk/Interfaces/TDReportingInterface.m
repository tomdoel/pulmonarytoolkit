classdef TDReportingInterface < handle
    % TDReportingInterface. Provides an interface for error and progress reporting.
    %
    %     TDReportingInterface is the interface the Pulmonary Toolkit uses to
    %     process errors, warnings, messages, logging information and progress
    %     reports. It is also used as a callback to the GUI (if it exists) for
    %     plugins to get the current orientation and marker image.
    %
    %     You can create your own implementation of this interface to get
    %     customised message behaviour; for example, if you are running a batch
    %     script you may wish to write all messages to a log file instead of
    %     displaying them on the command line.
    %
    %     This is an abstract class; you should not directly create an instance
    %     of TDReportingInterface. Instead, you should either use one of the
    %     existing implementation classes (TDReporting, TDReportingDefault) or
    %     you can create your own to achieve customised behaviour.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    
    methods (Abstract)
        
        % Writes debugging information to the log file
        Log(obj, message)
        
        % Displays an information message to the user. This will generally be
        % written to the command window
        ShowMessage(obj, identifier, message)
        
        % Displays an warning to the user. This will generally be
        % written to the command window. 
        ShowWarning(obj, identifier, message, supplementary_info)
        
        % Displays an error to the user. This may trigger an 
        % exception which will ultimately be displayed to the user as a modal
        % error dialog or written to the command window,
        Error(obj, identifier, message)
        
        % Displays an error to the user. Similar to Error() but also displays
        % additional information about an exception which triggered the error.
        ErrorFromException(obj, identifier, message, ex)

        % Displays the progress dialog with the specified title
        ShowProgress(obj, text)
        
        % Hides the progress dialog
        CompleteProgress(obj)
        
        % Changes the subtext in the progress dialog
        UpdateProgressMessage(obj, text)
        
        % Changes the percentage complete in the progress dialog, displaying if
        % necessary
        UpdateProgressValue(obj, progress_value)
         
        % When progress reporting consists of a number of stages, use this
        % method to ensure progress is handled correctly
        UpdateProgressStage(obj, progress_stage, num_stages)
        
        % Changes the percentage complete and subtext in the progress dialog,
        % displaying if necessary
        UpdateProgressAndMessage(obj, progress_value, text)
        
        % Used to check if the user has clicked the cancel button in the
        % progress dialog
        cancelled = HasBeenCancelled(obj)
        
        % Forces an exception if the user has clicked cancel in the progress
        % dialog
        CheckForCancel(obj)

        % Instructs the GUI (if it exists) to change the current view
        % coordinates
        ChangeViewingPosition(obj, coordinates)
        
        % Obtains the current orientation of the GUI (if it exists), where
        % 1 = coronal, 2 = sagittal, 3 = axial
        orientation = GetOrientation(obj)
        
        % Obtains the current marker image from the GUI (if it exists). Only
        % used by plugins which need to interact with the marker image used wit
        % the GUI.
        marker_image = GetMarkerImage(obj)
    end
end

