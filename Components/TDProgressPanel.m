classdef TDProgressPanel < TDProgressInterface
    % TDProgressPanel. A panel used to report progress informaton
    %
    %     TDProgressPanel implements the TDProgressInterface, which is an
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
        PanelHandle
        Disabled = false
        
        ProgressBarHandle
        Text
        Title
        Cancel
        Quit

        Parent
        IncrementThreshold = 5
        DialogText
        DialogTitle = ''
        ProgressValue = 0
        
        Hold = false;
        ShowProgressBar = false

        UserClickedCancel = false
        
    end
    
    properties (GetAccess = private, Constant)
        OpacityLevel = 0.85
        Width = 500
        Height = 250
    end
    
    methods
        
        
        function obj = TDProgressPanel(parent)
            obj.Parent = parent;
            
            set(parent, 'Units', 'Pixels');
            
            % Create the panel
            panel_background_colour = [0.0 0.129 0.278];
            progress_position = obj.GetPanelPosition;
            obj.PanelHandle = uipanel('Parent', parent, 'Title', '', 'BorderType', 'etchedin', 'ForegroundColor', 'white', ...
                'BackgroundColor', panel_background_colour, 'Units', 'pixels', 'Position', progress_position, 'Visible', 'off' ...
            );
            
            title_position = [20, 165, 460, 55];
            text_position = [20, 115, 460, 45];
            cancel_position = [70, 20, 150, 40];
            quit_position = [280, 20, 150, 40];
            progress_bar_position = [50, 90, 400, 18];
            
            
            obj.Title = uicontrol('parent', obj.PanelHandle, 'style', 'text', 'units', 'pixel', 'Position', title_position, ...
                'string', 'Please wait', 'FontUnits', 'pixels', 'FontSize', 26, 'FontWeight', 'bold', 'Fore', 'white', 'Back', [0, 0.129, 0.278], 'Visible', 'off');
            obj.Text = uicontrol('parent', obj.PanelHandle, 'style', 'text', 'units', 'pixel', 'Position', text_position, ...
                'string', 'Please wait', 'FontUnits', 'pixels', 'FontSize', 16, 'Fore', 'white', 'Back', [0, 0.129, 0.278], 'Visible', 'off');
            obj.Cancel = uicontrol('parent', obj.PanelHandle, 'string', 'Cancel', ...
                'Position', cancel_position, 'FontUnits', 'pixels', 'Callback', @obj.CancelButton, 'Visible', 'off');
            obj.Quit = uicontrol('parent', obj.PanelHandle, 'string', 'Force Quit', ...
                'Position', quit_position, 'FontUnits', 'pixels', 'Callback', @obj.QuitButton, 'Visible', 'off');
            
            [obj.ProgressBarHandle, ~] = javacomponent('javax.swing.JProgressBar', ...
                progress_bar_position, obj.PanelHandle);
            obj.ProgressBarHandle.setValue(0);
        end
        
        function Resize(obj)
            set(obj.PanelHandle, 'Position', obj.GetPanelPosition);
        end
        
        function ShowAndHold(obj, text)
            if nargin < 2
                text = 'Please wait';
            end
            obj.Hide;
            obj.DialogTitle = TDTextUtilities.RemoveHtml(text);
            obj.DialogText = '';
            obj.ProgressValue = 0;
            obj.Hold = true;
            obj.Update;
            obj.ShowPanel;
            obj.UserClickedCancel = false;
            drawnow;
        end
        
        function Hide(obj)
            obj.DialogTitle = 'Please wait';
            obj.ShowProgressBar = false;

            obj.HidePanel;
            obj.Hold = false;
            drawnow;
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
            drawnow;
        end
        
        function SetProgressText(obj, text)
            if nargin < 2
               text = 'Please wait'; 
            end            
            obj.DialogText = TDTextUtilities.RemoveHtml(text);
            obj.Update;
            obj.ShowPanel;            
            drawnow;
        end
        
        function SetProgressValue(obj, progress_value)
            obj.ProgressValue = progress_value;
            obj.ShowProgressBar = true;
            obj.Update;
            obj.ShowPanel;
            drawnow;
        end
        
        function SetProgressAndMessage(obj, progress_value, text)
            obj.ShowProgressBar = true;
            obj.DialogText = TDTextUtilities.RemoveHtml(text);
            obj.ProgressValue = progress_value;
            obj.Update;
            obj.ShowPanel;            
            drawnow;
        end
        
        function cancelled = CancelClicked(obj)
            cancelled = obj.UserClickedCancel;
            obj.UserClickedCancel = false;
        end
    end
    
    methods (Access = private)
        function Update(obj)
            set(obj.Title, 'String', obj.DialogTitle);
            set(obj.Text, 'String', obj.DialogText);
            obj.ProgressBarHandle.setValue(obj.ProgressValue);
        end
        
        function ShowPanel(obj)
            if obj.Disabled
                return;
            end            
            set(obj.PanelHandle, 'Visible', 'on');
            set(obj.Text, 'Visible', 'on');
            set(obj.Title, 'Visible', 'on');
            set(obj.Quit, 'Visible', 'on');
            set(obj.Cancel, 'Visible', 'on');
            set(obj.ProgressBarHandle, 'visible', 1);
        end
        
        function HidePanel(obj)
            if obj.Disabled
                return;
            end
            
            set(obj.Text, 'Visible', 'off');
            set(obj.Title, 'Visible', 'off');
            set(obj.Quit, 'Visible', 'off');
            set(obj.Cancel, 'Visible', 'off');
            set(obj.ProgressBarHandle, 'visible', 0);
            set(obj.PanelHandle, 'Visible', 'off');
        end
        
        function CancelButton(obj, ~, ~)
            obj.UserClickedCancel = true;
        end
        
        function QuitButton(obj, ~, ~)
            obj.Hide;
            throw(MException('TDCustomProgressDialog:UserForceQuit', 'User forced plugin to terminate'));
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

