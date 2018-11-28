classdef (Sealed) MimSplashScreen < CoreProgressInterface & GemFigure
    % MimSplashScreen. A splash screen dialog which also reports progress informaton
    %
    %     MimSplashScreen creates a dialog with the application logo and version
    %     information. It also displays progress information, for use during the
    %     application startup for reporting progress before the user interface
    %     is visible.
    %
    %     MimSplashScreen is a singleton. You cannot create it using the
    %     constructor; instead call MimSplashScreen.GetSplashScreen;
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        AppDef
        Image
        TitleText
        BodyText
        PanelHandle
        Disabled = false
        
        ProgressBarHandle
        Text
        ProgressTitle
        Cancel
        Quit
        UserClickedCancel = false

        IncrementThreshold = 5
        HandleToWaitDialog
        DialogText
        DialogTitle = ''
        ProgressValue = 0
        
        Hold = false;
        ShowProgressBar = false
        
        TimerRef
        MaxTimeBetweenUpdates = 0.25
        
        PanelIsShown = false
        LastText
        LastTitle
        
        ShowQuitButton = false
    end
        
    methods (Static)
        function splash_screen = GetSplashScreen(app_def)
            persistent SplashScreen
            if nargin < 1
                app_def = MivAppDef;
            end
            if isempty(SplashScreen) || ~isvalid(SplashScreen)
                SplashScreen = MimSplashScreen(app_def);
            end
            splash_screen = SplashScreen;
        end
    end
    
    methods (Access = private)
        function obj = MimSplashScreen(app_def)
            
            % Calculate the figure windows size
            set(0, 'Units', 'pixels');
            screen_size = get(0, 'ScreenSize');
            position = [1, 1, 700, 300];
            position(1) = max(1, round((screen_size(3) - position(3))/2));
            position(2) = max(1, round((screen_size(4) - position(4))/2));
            
            % Call the base class to initialise the hidden window
            reporting = CoreReportingDefault;
            obj = obj@GemFigure('', position, reporting);
            obj.StyleSheet = app_def.GetDefaultStyleSheet;
            
            obj.TimerRef = tic;
            obj.AppDef = app_def;
            
            % Hide the progress bar
            obj.Hide;
            
            % Create the figure
            obj.Show;
            set(obj.ProgressBarHandle, 'visible', 0);
            
            drawnow;
        end
    end
    
    methods
        function delete(obj)
            delete(obj.GraphicalComponentHandle);
        end        

        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemFigure(obj, position);
            
            background_colour = obj.StyleSheet.TextPrimaryColour;
            text_colour = obj.StyleSheet.BackgroundColour;

            % Override the colour and resize behaviour
            set(obj.GraphicalComponentHandle, 'Color', background_colour, 'Resize', 'off');
            
            logo = imread(obj.AppDef.GetLogoFilename);
            image_size = size(logo);            
            screen_image_size = MimSplashScreen.GetOptimalLogoSize(image_size(2:-1:1), [30, 70, 223, 200]);
            
            obj.Image = axes('Parent', obj.GraphicalComponentHandle, 'Units', 'Pixels', 'Position', screen_image_size);
            image(logo, 'Parent', obj.Image);
            axis(obj.Image, 'off');
            obj.TitleText = uicontrol('Style', 'text', 'Units', 'Pixels', 'Position', [300, 210, 350, 75], 'String', obj.AppDef.GetName, 'FontName', obj.StyleSheet.Font, 'FontUnits', 'pixels', 'FontSize', 36, 'FontWeight', 'bold', 'ForegroundColor', text_colour, 'BackgroundColor', background_colour);
            
            obj.BodyText = uicontrol('Style', 'text', 'Units', 'Pixels', 'Position', [300, 130, 350, 110], 'FontName', obj.StyleSheet.Font, 'FontUnits', 'pixels', 'FontSize', 16, 'FontWeight', 'bold', 'ForegroundColor', text_colour, 'BackgroundColor', background_colour, 'HorizontalAlignment', 'Center');
            set(obj.BodyText, 'String', sprintf(['Version ' obj.AppDef.GetVersion]));
            
            % Create the progress reporting
            panel_background_colour = background_colour;
            text_color = text_colour;
            
            title_position = [250, 150, 450, 30];
            text_position = [250, 90, 450, 60];
            cancel_position = [400, 20, 140, 30];
            quit_position = [580, 20, 70, 30];
            progress_bar_position = [300, 70, 350, 18];
            
            
            obj.ProgressTitle = uicontrol('parent', obj.GraphicalComponentHandle, 'style', 'text', 'units', 'pixel', 'Position', title_position, ...
                'string', 'Please wait', 'FontUnits', 'pixels', 'FontSize', 22, 'FontWeight', 'bold', 'Fore', text_color, 'Back', panel_background_colour, 'Visible', 'off');
            obj.Text = uicontrol('parent', obj.GraphicalComponentHandle, 'style', 'text', 'units', 'pixel', 'Position', text_position, ...
                'string', 'Please wait', 'FontUnits', 'pixels', 'FontSize', 16, 'Fore', text_color, 'Back', panel_background_colour, 'Visible', 'off');
            obj.Cancel = uicontrol('parent', obj.GraphicalComponentHandle, 'string', 'Cancel', ...
                'FontUnits', 'pixels', 'Position', cancel_position, 'Visible', 'off', 'Callback', @obj.CancelButton);
            obj.Quit = uicontrol('parent', obj.GraphicalComponentHandle, 'string', 'Force Quit', ...
                'FontUnits', 'pixels', 'Position', quit_position, 'Visible', 'off', 'Callback', @obj.QuitButton);
            
            [obj.ProgressBarHandle, ~] = javacomponent('javax.swing.JProgressBar', progress_bar_position, obj.GraphicalComponentHandle);
            obj.ProgressBarHandle.setValue(0);
            set(obj.ProgressBarHandle, 'visible', 0);
        end        
                       
        function ShowAndHold(obj, text)
            if nargin < 2
                text = 'Please wait';
            end
            obj.Hide;
            obj.DialogTitle = CoreTextUtilities.RemoveHtml(text);
            obj.DialogText = '';
            obj.ProgressValue = 0;
            obj.Hold = true;
            obj.Update;
            obj.ShowPanel;
            obj.UserClickedCancel = false;
        end
        
        function Hide(obj)
            obj.DialogTitle = 'Please wait';
            obj.ShowProgressBar = false;

            obj.HidePanel;
            obj.Hold = false;
        end
        
        function Complete(obj)
            % Call to complete a progress operaton, which will also hide the dialog
            % unless the dialog is being held
            obj.ShowProgressBar = false;
            obj.ProgressValue = 100;
            if ~obj.Hold
                obj.Hide;
            else
                obj.DialogText = '';
                obj.Update;
            end
        end
        
        function SetProgressText(obj, text)
            if nargin < 2
               text = 'Please wait'; 
            end            
            obj.DialogText = CoreTextUtilities.RemoveHtml(text);
            obj.Update;
            obj.ShowPanel;            
        end
        
        function SetProgressValue(obj, progress_value)
            obj.ProgressValue = progress_value;
            obj.ShowProgressBar = true;
            obj.Update;
            obj.ShowPanel;
        end
        
        function SetProgressAndMessage(obj, progress_value, text)
            obj.ShowProgressBar = true;
            obj.DialogText = CoreTextUtilities.RemoveHtml(text);
            obj.ProgressValue = progress_value;
            obj.Update;
            obj.ShowPanel;            
        end
        
        function cancelled = CancelClicked(obj)
            cancelled = obj.UserClickedCancel;
            obj.UserClickedCancel = false;
        end
        
    end
    
    methods (Access = private)
        function Update(obj)
            if isempty(obj.LastTitle) || ~strcmp(obj.DialogTitle, obj.LastTitle)
                set(obj.ProgressTitle, 'String', obj.DialogTitle);
                obj.LastTitle = obj.DialogTitle;
            end
            
            if isempty(obj.LastText) || ~strcmp(obj.DialogText, obj.LastText)
                set(obj.Text, 'String', obj.DialogText);
                obj.LastText = obj.DialogText;
            end
            
            obj.ProgressBarHandle.setValue(obj.ProgressValue);
            
            if isempty(obj.TimerRef) || toc(obj.TimerRef) > obj.MaxTimeBetweenUpdates
                obj.TimerRef = tic;
                drawnow;
            end
        end
        
        function ShowPanel(obj)
            if obj.Disabled || obj.PanelIsShown
                return;
            end            
            set(obj.Text, 'Visible', 'on');
            set(obj.ProgressTitle, 'Visible', 'on');

            if obj.ShowQuitButton
                set(obj.Quit, 'Visible', 'on');
            end

            set(obj.Cancel, 'Visible', 'on');
            set(obj.ProgressBarHandle, 'visible', 1);
            
            obj.PanelIsShown = true;            
        end
        
        function HidePanel(obj)
            
            if obj.Disabled || ~obj.PanelIsShown
                return;
            end
            
            set(obj.Text, 'Visible', 'off');
            set(obj.ProgressTitle, 'Visible', 'off');
            set(obj.Quit, 'Visible', 'off');
            set(obj.Cancel, 'Visible', 'off');
            set(obj.ProgressBarHandle, 'visible', 0);
            obj.PanelIsShown = false;
        end
        
        function CancelButton(obj, ~, ~)
            obj.UserClickedCancel = true;
        end
        
        function QuitButton(obj, ~, ~)
            obj.Hide;
            throw(MException('MimCustomProgressDialog:UserForceQuit', 'User forced plugin to terminate'));
        end
    end
    
    methods (Static, Access = private)
        function logo_position = GetOptimalLogoSize(image_size, frame_position)
            frame_size = frame_position(3:4);
            if (image_size(1) > frame_size(1) || image_size(2) > frame_size(2))
                scale = max(ceil(image_size(1)/frame_size(1)), ceil(image_size(2)/frame_size(2)));
                scale = 1/scale;
            else
                scale = min(floor(frame_size(1)/image_size(1)), floor(frame_size(2)/image_size(2)));
            end
            scaled_image_size = scale*image_size;
            logo_position = [frame_position(1:2) + round((frame_size - scaled_image_size)/2), scaled_image_size];
        end
    end
    
end
