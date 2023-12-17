classdef CoreProgressDialog < CoreProgressInterface
    % CoreProgressDialog. A dialog used to report progress informaton
    %
    %     CoreProgressDialog creates and manages a waitbar to mark progress
    %     in operations performed by the coremat framework and related
    %     libraries. It provides a default implementation of
    %     CoreProgressInterface that can be used by your own code or can be
    %     instantiated automatically be functions when no progress
    %     interface object is provided.
    %
    %     GUI applications may prefer to create their own implementation of
    %     CoreProgressInterface which matches their application, rather
    %     than using this default implementation.
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %


    properties (Access = private)
        IncrementThreshold = 5
        HandleToWaitDialog
        DialogText = 'Please Wait'
        DialogTitle = ''
        ProgressValue = 0

        Hold = false
        ShowProgressBar = false
    end

    methods
        function ShowAndHold(obj, text)
            if nargin < 2
               text = 'Please wait';
            end
            obj.Hide();
            obj.DialogTitle = CoreTextUtilities.RemoveHtml(text);
            obj.DialogText = '';
            obj.ProgressValue = 0;
            obj.Hold = true;
            obj.Update();
        end

        function Hide(obj)
            obj.DialogTitle = 'Please wait';
            obj.ShowProgressBar = false;

#            if ishandle(obj.HandleToWaitDialog)
               delete(obj.HandleToWaitDialog)
#            end
            obj.Hold = false;
        end

        function Complete(obj)
            % Call to complete a progress operaton, which will also hide the dialog
            % unless the dialog is being held

            obj.ShowProgressBar = false;
            obj.ProgressValue = 100;
            if ~obj.Hold
                obj.Hide();
            else
                obj.Update();
            end
        end

        function SetProgressText(obj, text)
            if nargin < 2
               text = 'Please wait';
            end
            obj.DialogText = CoreTextUtilities.RemoveHtml(text);
            obj.Update();
        end

        function SetProgressValue(obj, progress_value)
            obj.ShowProgressBar = true;
            obj.Update();

            % ishandle is quite slow, so avoid too many Update() calls
            if abs(progress_value - obj.ProgressValue) >= obj.IncrementThreshold
                obj.ProgressValue = progress_value;
                obj.Update();
            end
        end

        function SetProgressAndMessage(obj, progress_value, text)
            obj.ShowProgressBar = true;
            obj.DialogText = CoreTextUtilities.RemoveHtml(text);
            obj.ProgressValue = progress_value;
            obj.Update();
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
            obj.Hide();
        end
    end

    methods (Access = private)

        function Update(obj)
            if ishandle(obj.HandleToWaitDialog)
                try
                    h = waitbar(double(obj.ProgressValue)/100, obj.HandleToWaitDialog, obj.DialogText);
                    set(findall(h, 'type', 'text'), 'Interpreter', 'none');
                catch ex
                    disp(ex);
                end
            else
                obj.HandleToWaitDialog = waitbar(obj.ProgressValue/100, obj.DialogText, 'Name', obj.DialogTitle, 'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
                set(findall(obj.HandleToWaitDialog, 'type', 'text'), 'Interpreter', 'none');
                setappdata(obj.HandleToWaitDialog, 'canceling', 0);
            end
        end


    end
end

