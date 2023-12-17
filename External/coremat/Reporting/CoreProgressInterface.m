classdef CoreProgressInterface < CoreBaseClass
    % CoreProgressInterface. Interface for classes which implement a progress bar.
    %
    %     The CoreReporting class uses this interface to display and update a
    %     progress bar and associated text. The CoreProgressDialog class
    %     implements the progress bar as a standard Matlab progress dialog,
    %     whereas other implementations may implement a custom progress panel for an
    %     existing figure.
    %
    %     You can implement custom progress reporting by creating a class which
    %     implements this interface, and then passing an instance of your
    %     progress class into CoreReporting.
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    methods (Abstract)
##        
##        % Indicates the gui has been resized
##        Resize(obj, panel_position)
##               
##        % Show the progress bar, and keep it displayed until Hide() is called
##        ShowAndHold(obj, text)
##        
##        % Hide the progress bar
##        Hide(obj)
##        
##        % Call to complete a progress operaton, which will also hide the dialog
##        % unless the dialog has been held by ShowAndHold()
##        Complete(obj)
##        
##        % Changes the subtext in the progress dialog
##        SetProgressText(obj, text)
##        
##        % Changes the value of the progress bar
##        SetProgressValue(obj, progress_value)
##        
##        % Changes the value of the progress bar and the subtext
##        SetProgressAndMessage(obj, progress_value, text)
##        
##        % Checks if the cancel button was clicked by the user
##        cancelled = CancelClicked(obj)
    end    
end

