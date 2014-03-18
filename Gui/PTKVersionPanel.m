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
        TopMargin = 10
        LeftMargin = 10
        RightMargin = 10
        ProfileCheckboxWidth = 100
        MinimumTextWidth = 200
        HorizontalSpacing = 10
        
        SoftwareNameFontSize = 20
        SoftwareNameHeight = 40
        SoftwareNameWidth = 300
        CurrentResultHeight = 30
        CurrentResultFontSize = 20
        
        NoPatientText = 'No dataset loaded'
        
        PatientNameHeight = 40
        PatientNameFontSize = 40
        
        VerticalSpacing = 10
        CheckboxVerticalOffset = 20
        CheckboxHeight = 20
        CheckboxFontSize = 10
        
        PatientDetailsHeight = 20
        PatientDetailsFontSize = 20
    end
    
    methods
        function obj = PTKVersionPanel(parent, gui, settings, reporting)
            obj = obj@PTKPanel(parent, reporting);
            
            obj.Gui = gui;
            obj.Settings = settings;
            
            obj.SoftwareNameText = PTKText(obj, [PTKSoftwareInfo.Name ' version ' PTKSoftwareInfo.Version] , '', 'SoftwareName');
            obj.SoftwareNameText.FontSize = obj.SoftwareNameFontSize;
            obj.SoftwareNameText.FontColour = PTKSoftwareInfo.TextSecondaryColour;
            obj.AddChild(obj.SoftwareNameText);

            obj.DeveloperModeCheckbox = PTKCheckbox(obj, 'Developer mode', 'Enabled developer mode', 'DeveloperMode');
            obj.DeveloperModeCheckbox.FontSize = obj.CheckboxFontSize;
            obj.DeveloperModeCheckbox.ChangeChecked(obj.Settings.DeveloperMode);
            obj.AddChild(obj.DeveloperModeCheckbox);
            
            % Add listener for changes to the developer mode check box
            obj.AddEventListener(obj.DeveloperModeCheckbox, 'CheckChanged', @obj.DeveloperCheckChanged);
            
            % Add the profiler checkbox but disable if developer mode is off
            obj.ProfileCheckbox = PTKCheckbox(obj, 'Enable Profiler', 'Starts or stops the Matlab profiler', 'Profiler');
            obj.ProfileCheckbox.FontSize = obj.CheckboxFontSize;
            obj.AddChild(obj.ProfileCheckbox);
            if ~obj.Settings.DeveloperMode
                obj.ProfileCheckbox.Disable;
            end
            obj.AddEventListener(obj.ProfileCheckbox, 'CheckChanged', @obj.ProfileCheckChanged);
            

            obj.PatientNameText = PTKText(obj, obj.NoPatientText, '', 'PatientName');
            obj.PatientNameText.FontSize = obj.PatientNameFontSize;
            obj.AddChild(obj.PatientNameText);
            
            obj.PatientDetailsText = PTKText(obj, 'No details', '', 'PatientDetails');
            obj.PatientDetailsText.FontSize = obj.PatientDetailsFontSize;
            obj.AddChild(obj.PatientDetailsText);

            obj.CurrentResultText = PTKText(obj, '', '', 'CurrentResult');
            obj.CurrentResultText.FontSize = obj.CurrentResultFontSize;
            obj.CurrentResultText.FontColour = PTKSoftwareInfo.TextSecondaryColour;
            obj.AddChild(obj.CurrentResultText);
            
            % Update the profile checkbox with the current status of the Matlab
            % profilers
            obj.UpdateProfilerStatus;                        
        end
        
        function UpdatePatientName(obj, series_name, patient_visible_name, plugin_visible_name, is_edited)
            
            if is_edited
                edited_line = 'Edited ';
            else
                edited_line = '';
            end
            
            if isempty(plugin_visible_name)
                result_name = '';
            else
                result_name = [edited_line, plugin_visible_name];
            end
            
            obj.PatientNameText.ChangeText(patient_visible_name);
            obj.PatientDetailsText.ChangeText(series_name);
            obj.CurrentResultText.ChangeText(result_name);
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

            software_name_y = panel_position(4) - obj.TopMargin - obj.SoftwareNameHeight;
            patient_name_y = software_name_y - obj.VerticalSpacing - obj.PatientNameHeight;
            patient_details_y = patient_name_y - obj.VerticalSpacing - obj.PatientDetailsHeight;
            result_name_y = patient_details_y - obj.VerticalSpacing - obj.CurrentResultHeight;
            
            obj.SoftwareNameText.Resize([obj.LeftMargin, software_name_y, obj.SoftwareNameWidth, obj.SoftwareNameHeight]);
            obj.PatientNameText.Resize([obj.LeftMargin, patient_name_y, componenent_width, obj.PatientNameHeight]);
            obj.PatientDetailsText.Resize([obj.LeftMargin, patient_details_y, componenent_width, obj.PatientDetailsHeight]);
            obj.CurrentResultText.Resize([obj.LeftMargin, result_name_y, obj.SoftwareNameWidth, obj.CurrentResultHeight]);
            
            checkbox_xpos = obj.LeftMargin + obj.SoftwareNameWidth + obj.HorizontalSpacing;
            checkbox_width = max(10, componenent_width - checkbox_xpos);

            developer_checkbox_position = [checkbox_xpos, software_name_y + obj.CheckboxVerticalOffset, checkbox_width, obj.CheckboxHeight];
            profile_checkbox_position = [checkbox_xpos, software_name_y, checkbox_width, obj.CheckboxHeight];
            
            obj.DeveloperModeCheckbox.Resize(developer_checkbox_position);
            obj.ProfileCheckbox.Resize(profile_checkbox_position);            
        end
        
        function height = GetRequestedHeight(obj, width)            
            height = obj.TopMargin + obj.PatientNameHeight + obj.PatientDetailsHeight + obj.SoftwareNameHeight +  obj.CurrentResultHeight + 4*obj.VerticalSpacing;
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
        
        function display_string = GetSoftwareNameAndVersionForDisplay(~)
            % Set the application name and version number
            
            display_string = [PTKSoftwareInfo.Name, ' version ' PTKSoftwareInfo.Version];
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