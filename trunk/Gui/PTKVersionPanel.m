classdef PTKVersionPanel < PTKPanel
    % PTKVersionPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKVersionPanel shows the program title and version
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (Access = private)
        SoftwareNameText
        PatientNameText
        PatientDetailsText
        CurrentResultText
        ProfileCheckbox
        DeveloperModeCheckbox
        
        TextBlankHandle
        
        Gui
        Settings
    end
    
    properties (Constant, Access = private)
        TopMargin = 5
        LeftMargin = 5
        RightMargin = 5
        BottomMargin = 5
        CheckboxHeight = 20
        CheckboxVerticalSpacing = 5
        CheckboxWidth = 100
        CheckboxFontSize = 10
    end
    
    methods
        function obj = PTKVersionPanel(parent, gui, settings, reporting)
            obj = obj@PTKPanel(parent, reporting);
            
            obj.Gui = gui;
            obj.Settings = settings;

            obj.DeveloperModeCheckbox = PTKCheckbox(obj, 'Developer mode', 'Enabled developer mode', 'DeveloperMode');
            obj.DeveloperModeCheckbox.FontSize = obj.CheckboxFontSize;
            obj.DeveloperModeCheckbox.ChangeChecked(obj.Settings.DeveloperMode);
            obj.AddChild(obj.DeveloperModeCheckbox, obj.Reporting);
            
            % Add listener for changes to the developer mode check box
            obj.AddEventListener(obj.DeveloperModeCheckbox, 'CheckChanged', @obj.DeveloperCheckChanged);
            
            % Add the profiler checkbox but disable if developer mode is off
            obj.ProfileCheckbox = PTKCheckbox(obj, 'Enable Profiler', 'Starts or stops the Matlab profiler', 'Profiler');
            obj.ProfileCheckbox.FontSize = obj.CheckboxFontSize;
            obj.AddChild(obj.ProfileCheckbox, obj.Reporting);
            if ~obj.Settings.DeveloperMode
                obj.ProfileCheckbox.Disable;
            end
            obj.AddEventListener(obj.ProfileCheckbox, 'CheckChanged', @obj.ProfileCheckChanged);
            
            % Update the profile checkbox with the current status of the Matlab
            % profilers
            obj.UpdateProfilerStatus;                        
        end
        
        function CreateGuiComponent(obj, panel_position, reporting)
            CreateGuiComponent@PTKPanel(obj, panel_position, reporting);

            blank_text_position = [1, 1, panel_position(3), panel_position(4)];
                        
            obj.TextBlankHandle = uicontrol('Parent', obj.GraphicalComponentHandle, 'Style', 'text', ...
                'Units', 'pixels', 'Position', blank_text_position, 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, ...
                'FontName', PTKSoftwareInfo.GuiFont, 'FontSize', 20.0, 'ForegroundColor', [1.0 0.694 0.392], 'HorizontalAlignment', 'left', ...
                'FontWeight', 'bold');
            
        end
        
        function Resize(obj, panel_position)
            Resize@PTKPanel(obj, panel_position);
            
            if ~isempty(obj.TextBlankHandle)
                blank_text_position = [1, 1, panel_position(3), panel_position(4)];
                set(obj.TextBlankHandle, 'Position', blank_text_position);
            end
            
            componenent_width = panel_position(3) - obj.LeftMargin - obj.RightMargin;

            checkbox_top = panel_position(4) - obj.TopMargin - obj.CheckboxHeight;
            checkbox_bottom = obj.BottomMargin;
            
            checkbox_xpos = obj.LeftMargin; % + obj.SoftwareNameWidth + obj.HorizontalSpacing;
            checkbox_width = max(10, componenent_width - obj.LeftMargin - obj.RightMargin);

            developer_checkbox_position = [checkbox_xpos, checkbox_top, checkbox_width, obj.CheckboxHeight];
            profile_checkbox_position = [checkbox_xpos, checkbox_bottom, checkbox_width, obj.CheckboxHeight];
            
            obj.DeveloperModeCheckbox.Resize(developer_checkbox_position);
            obj.ProfileCheckbox.Resize(profile_checkbox_position);            
        end
        
        function height = GetRequestedHeight(obj, width)            
            height = obj.TopMargin + obj.BottomMargin + 2*obj.CheckboxHeight + obj.CheckboxVerticalSpacing;
        end
        
    end
    
    methods (Access = private)
        
        function DeveloperCheckChanged(obj, ~, event_data)
            % Enters or exits developer mode
            enabled = event_data.Data;
            obj.Settings.DeveloperMode = enabled;
            if enabled
                obj.ProfileCheckbox.Enable(obj.Reporting);
            else
                obj.ProfileCheckbox.Disable;
            end
            obj.Gui.RefreshPlugins;
        end
        
        function ProfileCheckChanged(obj, ~, event_data)
            % Enables or disables (and shows) Matlab's profiler when the profile checkbox is
            % changed
            if event_data.Data
                profile on
            else
                profile viewer
            end
        end
        
        function UpdateProfilerStatus(obj)
            % Updates the "Show profile" check box according to the current running state
            % of the Matlab profiler
            profile_status = profile('status');
            if strcmp(profile_status.ProfilerStatus, 'on')
                obj.ProfileCheckbox.ChangeChecked(true);
            else
                obj.ProfileCheckbox.ChangeChecked(false);
            end
        end
        
        
    end
end