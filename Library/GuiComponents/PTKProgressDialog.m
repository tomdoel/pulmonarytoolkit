classdef PTKProgressDialog < PTKProgressInterface
    % PTKProgressDialog. A dialog used to report progress informaton
    %
    %     PTKProgressDialog implements the PTKProgressInterface, which is an
    %     interface used by the Pulmonary Toolkit to report the progress of
    %     operations.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        IncrementThreshold = 5
        HandleToWaitDialog
        DialogText = 'Please Wait'
        DialogTitle = ''
        ProgressValue = 0
        
        Hold = false;
        ShowProgressBar = false
    end

    methods
        function ShowAndHold(obj, text)
            if nargin < 2
               text = 'Please wait'; 
            end
            obj.Hide;
            obj.DialogTitle = PTKTextUtilities.RemoveHtml(text);
            obj.DialogText = '';
            obj.ProgressValue = 0;
            obj.Hold = true;
            obj.Update;
        end
        
        function Hide(obj)
            obj.DialogTitle = 'Please wait';
            obj.ShowProgressBar = false;

            if ishandle(obj.HandleToWaitDialog)
               delete(obj.HandleToWaitDialog) 
            end
            obj.Hold = false;
        end
        
        % Call to complete a progress operaton, which will also hide the dialog
        % unless the dialog is being held
        function Complete(obj)
            obj.ShowProgressBar = false;
            obj.ProgressValue = 100;
            if ~obj.Hold
                obj.Hide;
            else
                obj.Update;
            end
        end
        
        function SetProgressText(obj, text)
            if nargin < 2
               text = 'Please wait'; 
            end            
            obj.DialogText = PTKTextUtilities.RemoveHtml(text);
            obj.Update;
        end
        
        function SetProgressValue(obj, progress_value)
            obj.ShowProgressBar = true;
            obj.Update;
            
            % ishandle is quite slow, so avoid too many Update() calls
            if abs(progress_value - obj.ProgressValue) >= obj.IncrementThreshold;
                obj.ProgressValue = progress_value;
                obj.Update;
            end
        end
        
        function SetProgressAndMessage(obj, progress_value, text)
            obj.ShowProgressBar = true;
            obj.DialogText = PTKTextUtilities.RemoveHtml(text);
            obj.ProgressValue = progress_value;
            obj.Update;
        end
        
        function cancelled = CancelClicked(obj)
            if ishandle(obj.HandleToWaitDialog)
                cancelled = getappdata(obj.HandleToWaitDialog, 'canceling');
            else
                cancelled = false;
            end
        end
        
        function Resize(~)
        end
        
        function delete(obj)
            obj.Hide;
        end        
    end
    
    methods (Access = private)
        
        function Update(obj)
            if ishandle(obj.HandleToWaitDialog)
                waitbar(double(obj.ProgressValue)/100, obj.HandleToWaitDialog, obj.DialogText);
            else
                obj.HandleToWaitDialog = waitbar(obj.ProgressValue/100, obj.DialogText, 'Name', obj.DialogTitle, 'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
                setappdata(obj.HandleToWaitDialog, 'canceling', 0);
            end
        end
        
        
    end
end

