classdef PTKProgressPanel < PTKProgressInterface
    % PTKProgressPanel. A panel used to report progress informaton
    %
    %     PTKProgressPanel implements the PTKProgressInterface, which is an
    %     interface used by the Pulmonary Toolkit to report the progress of
    %     operations. This panel is displayed over the centre of the panel
    %     object whose handle is supplied in the constructor.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        
        % Handles to the GUI components
        Parent
        PanelHandle
        UiControlTitle
        UiControlText
        UiControlCancel
        UiControlQuit
        UiControlHide
        ProgressBarHandle

        IncrementThreshold = 5

        % Flags
        Hold = false;
        ShowProgressBar = false
        UserClickedCancel = false

        % The current values
        DialogText
        DialogTitle = ''
        ProgressValue = 0
        PanelVisibility = false;
        
        
        % The previous values
        CurrentlyDisplayedDialogTitle
        CurrentlyDisplayedDialogText
        CurrentlyDisplayedProgressValue
        CurrentlyDisplayedVisibility = false
        ProgressBarCurrentlyVisible = false;
    end
    
    properties (GetAccess = private, Constant)
        OpacityLevel = 0.85
        Width = 500
        Height = 250
    end
    
    methods
        
        
        function obj = PTKProgressPanel(parent)
            obj.CurrentlyDisplayedDialogTitle = '';
            obj.CurrentlyDisplayedDialogText = '';
            obj.CurrentlyDisplayedProgressValue = [];
            
            obj.Parent = parent;
            
            set(parent, 'Units', 'Pixels');
            
            % Create the panel
            panel_background_colour = PTKSoftwareInfo.BackgroundColour;
            progress_position = obj.GetPanelPosition;
            obj.PanelHandle = uipanel('Parent', parent, 'Title', '', 'BorderType', 'etchedin', 'ForegroundColor', 'white', ...
                'BackgroundColor', panel_background_colour, 'Units', 'pixels', 'Position', progress_position, 'Visible', 'off' ...
            );
            
            title_position = [20, 165, 460, 55];
            text_position = [20, 115, 460, 50];
            cancel_position = [175, 20, 150, 40];
            quit_position = [370, 20, 80, 40];
            hide_position = [50, 20, 80, 40];
            progress_bar_position = [50, 90, 400, 18];
            
            
            obj.UiControlTitle = uicontrol('parent', obj.PanelHandle, 'style', 'text', 'units', 'pixel', 'Position', title_position, ...
                'string', 'Please wait', 'FontUnits', 'pixels', 'FontSize', 26, 'FontWeight', 'bold', 'Fore', 'white', 'Back', [0, 0.129, 0.278], 'Visible', 'off');
            obj.UiControlText = uicontrol('parent', obj.PanelHandle, 'style', 'text', 'units', 'pixel', 'Position', text_position, ...
                'string', 'Please wait', 'FontUnits', 'pixels', 'FontSize', 16, 'Fore', 'white', 'Back', [0, 0.129, 0.278], 'Visible', 'off');
            obj.UiControlCancel = uicontrol('parent', obj.PanelHandle, 'string', 'Cancel', ...
                'Position', cancel_position, 'FontUnits', 'pixels', 'Callback', @obj.CancelButton, 'Visible', 'off');
            obj.UiControlQuit = uicontrol('parent', obj.PanelHandle, 'string', 'Force Quit', ...
                'Position', quit_position, 'FontUnits', 'pixels', 'Callback', @obj.QuitButton, 'Visible', 'off');
            obj.UiControlHide = uicontrol('parent', obj.PanelHandle, 'string', 'Hide Dialog', ...
                'Position', hide_position, 'FontUnits', 'pixels', 'Callback', @obj.HideButton, 'Visible', 'off');
            
            [obj.ProgressBarHandle, ~] = javacomponent('javax.swing.JProgressBar', ...
                progress_bar_position, obj.PanelHandle);
            obj.ProgressBarHandle.setBackground(java.awt.Color(panel_background_colour(1), panel_background_colour(2), panel_background_colour(3)));
            set(obj.ProgressBarHandle, 'visible', 0);
        end
        
        function Resize(obj)
            set(obj.PanelHandle, 'Position', obj.GetPanelPosition);
        end
        
        function ShowAndHold(obj, text)
            if nargin < 2
                text = 'Please wait';
            end
            obj.DialogTitle = PTKTextUtilities.RemoveHtml(text);
            obj.DialogText = '';
            obj.ProgressValue = 0;
            obj.Hold = true;
            obj.UserClickedCancel = false;
            obj.PanelVisibility = true;
            obj.ShowProgressBar = false;
            obj.Update;
        end
        
        function Hide(obj)
            obj.DialogTitle = 'Please wait';
            obj.Hold = false;
            obj.PanelVisibility = false;
            obj.ShowProgressBar = false;
            obj.Update;
        end
        
        % Call to complete a progress operaton, which will also hide the dialog
        % unless the dialog is being held
        function Complete(obj)
            obj.ShowProgressBar = false;
            obj.ProgressValue = 100;
            if ~obj.Hold
                obj.PanelVisibility = false;
            else
                obj.SetProgressText('');
            end
            obj.Update;
        end
        
        function SetProgressText(obj, text)
            if nargin < 2
               text = 'Please wait'; 
            end            
            obj.DialogText = PTKTextUtilities.RemoveHtml(text);
            obj.PanelVisibility = true;
            obj.Update;
        end
        
        function SetProgressValue(obj, progress_value)
            obj.ShowProgressBar = true;
            obj.ProgressValue = progress_value;
            obj.PanelVisibility = true;
            obj.Update;
        end
        
        function SetProgressAndMessage(obj, progress_value, text)
            obj.ShowProgressBar = true;
            obj.DialogText = PTKTextUtilities.RemoveHtml(text);
            obj.ProgressValue = progress_value;
            obj.PanelVisibility = true;
            obj.Update;
        end
        
        function cancelled = CancelClicked(obj)
            cancelled = obj.UserClickedCancel;
            obj.UserClickedCancel = false;
        end
    end
    
    methods (Access = private)
        function changed = Update(obj)
            changed = false;
            changed = obj.UpdateDialogTitle || changed;
            changed = obj.UpdateDialogText || changed;
            changed = obj.UpdateProgressValue || changed;
            changed = obj.UpdateVisibility || changed;
            changed = obj.UpdateProgressBarVisibility || changed;
            if changed
                drawnow;
                changed = false;
            end
        end
        
        function changed = UpdateDialogTitle(obj)
            changed = false;
            if ~strcmp(obj.DialogTitle, obj.CurrentlyDisplayedDialogTitle)
                set(obj.UiControlTitle, 'String', obj.DialogTitle);
                obj.CurrentlyDisplayedDialogTitle = obj.DialogTitle;
                changed = true;
            end
        end
        
        function changed = UpdateDialogText(obj)
            changed = false;
            if ~strcmp(obj.DialogText, obj.CurrentlyDisplayedDialogText)
                set(obj.UiControlText, 'String', obj.DialogText);
                obj.CurrentlyDisplayedDialogText = obj.DialogText;
                changed = true;
            end            
        end
        
        function changed = UpdateProgressValue(obj)
            changed = false;
            if ~isequal(obj.ProgressValue, obj.CurrentlyDisplayedProgressValue)
                obj.ProgressBarHandle.setValue(obj.ProgressValue);
                obj.CurrentlyDisplayedProgressValue = obj.ProgressValue;
                changed = true;
            end            
        end
        
        function changed = UpdateProgressBarVisibility(obj)
            changed = false;
            if ~obj.ProgressBarCurrentlyVisible && obj.ShowProgressBar && obj.PanelVisibility 
                set(obj.ProgressBarHandle, 'visible', 1);
                obj.ProgressBarCurrentlyVisible = true;
                changed = true;
            elseif obj.ProgressBarCurrentlyVisible && (~obj.ShowProgressBar || ~obj.PanelVisibility)
                set(obj.ProgressBarHandle, 'visible', 0);
                obj.ProgressBarCurrentlyVisible = false;
                changed = true;
            end
        end
        
        function changed = UpdateVisibility(obj)
            changed = false;
            if obj.PanelVisibility && ~obj.CurrentlyDisplayedVisibility
                set(obj.PanelHandle, 'Visible', 'on');
                set(obj.UiControlText, 'Visible', 'on');
                set(obj.UiControlTitle, 'Visible', 'on');
                if PTKSoftwareInfo.DebugMode
                    set(obj.UiControlQuit, 'Visible', 'on');
                    set(obj.UiControlHide, 'Visible', 'on');
                end
                set(obj.UiControlCancel, 'Visible', 'on');
                obj.CurrentlyDisplayedVisibility = true;
                changed = true;
            elseif ~obj.PanelVisibility && obj.CurrentlyDisplayedVisibility
                set(obj.UiControlText, 'Visible', 'off');
                set(obj.UiControlTitle, 'Visible', 'off');
                set(obj.UiControlQuit, 'Visible', 'off');
                set(obj.UiControlHide, 'Visible', 'off');
                set(obj.UiControlCancel, 'Visible', 'off');
                set(obj.ProgressBarHandle, 'visible', 0);
                set(obj.PanelHandle, 'Visible', 'off');
                obj.CurrentlyDisplayedVisibility = false;
                obj.ProgressBarCurrentlyVisible = false;
                changed = true;
            end
        end
        
        function CancelButton(obj, ~, ~)
            obj.UserClickedCancel = true;
            obj.PanelVisibility = false;
            obj.Hold = false;
            obj.Update;
        end
        
        function QuitButton(obj, ~, ~)
            obj.PanelVisibility = false;
            obj.Hold = false;
            obj.UpdateVisibility;
            throw(MException('PTKProgressPanel:UserForceQuit', 'User forced plugin to quit'));
        end

        function HideButton(obj, ~, ~)
            obj.PanelVisibility = false;
            obj.Hold = false;
            obj.UpdateVisibility;
        end
        
        function progress_position = GetPanelPosition(obj)
            panel_position = get(obj.Parent, 'Position');

            window_width = panel_position(3);
            window_height = panel_position(4);
            progress_width = min(obj.Width, window_width);
            progress_height = min(obj.Height, window_height);
            progress_x = max(1, round((window_width - progress_width)/2));
            progress_y = max(1, (2/3)*round((window_height - progress_height)));
            progress_position = [progress_x, progress_y, progress_width, progress_height];
        end

    end
end

