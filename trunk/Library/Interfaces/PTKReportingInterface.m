classdef PTKReportingInterface < handle
    % PTKReportingInterface. Provides an interface for error and progress reporting.
    %
    %     PTKReportingInterface is the interface the Pulmonary Toolkit uses to
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
    %     of PTKReportingInterface. Instead, you should either use one of the
    %     existing implementation classes (PTKReporting, PTKReportingDefault) or
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
        
        % Writes debugging information to the log file, but only if in verbose
        % mode
        LogVerbose(obj, message)

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
        
        % Obtains the current orientation of the GUI (if it exists)
        orientation = GetOrientation(obj)
        
        % Instructs the GUI (if it exists) to change the current view
        % orientation, where Orientation is of type PTKImageOrientation
        ChangeViewingOrientation(obj, orientation)
        
        % Obtains the current marker image from the GUI (if it exists). Only
        % used by plugins which need to interact with the marker image used wit
        % the GUI.
        marker_image = GetMarkerImage(obj)

        % Nests progress reporting. After calling this function, subsequent
        % progress updates will modify the progress bar between the current
        % value ane the current value plus the last value_change.
        PushProgress(obj)

        % Removes one layer of progress nesting, returning to the previous
        % progress reporting.
        PopProgress(obj)
        
        % Clears all progress nesting
        ClearProgressStack(obj)
        
        % Show any error or warning messages and clear the message stack
        ShowAndClearPendingMessages(obj)
        
        % Used to update any viewing panels attached to this reporting object
        UpdateOverlayImage(obj, new_image)
        
        % Used to update any viewing panels attached to this reporting object
        UpdateOverlaySubImage(obj, new_image)
        
        % Signals that a path should be opened or otherwise alerted to the user
        OpenPath(obj, file_path, message)

    end
end

