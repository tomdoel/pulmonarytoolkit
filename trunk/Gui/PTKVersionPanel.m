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
        TextVersionHandle
        TextBlankHandle
        UipanelVersionHandle
        ProfileCheckboxHandle
    end
    
    properties (Constant, Access = private)
        LeftMargin = 10
        RightMargin = 10
        ProfileCheckboxWidth = 100
        MinimumTextWidth = 200
        HorizontalSpacing = 50;
    end
    
    methods
        function obj = PTKVersionPanel(parent, reporting)
            obj = obj@PTKPanel(parent, reporting);
        end
        
        function delete(obj)
        end
        
        function CreateGuiComponent(obj, panel_position, reporting)
            CreateGuiComponent@PTKPanel(obj, panel_position, reporting);
            
            text_width = panel_position(3) - obj.LeftMargin - obj.RightMargin - obj.HorizontalSpacing - obj.ProfileCheckboxWidth;
            text_width = max(obj.MinimumTextWidth, text_width);
            checkbox_pos = obj.LeftMargin + text_width + obj.HorizontalSpacing;
            checkbox_width = panel_position(3) - checkbox_pos;
            
            blank_text_position = [1, 1, panel_position(3), panel_position(4)];
            text_position = [obj.LeftMargin, 1, panel_position(3), panel_position(4)];
            profile_checkbox_position = [checkbox_pos, 1, checkbox_width, panel_position(4)];
                        
            obj.TextBlankHandle = uicontrol('Parent', obj.GraphicalComponentHandle, 'Style', 'text', ...
                'Units', 'pixels', 'Position', blank_text_position, 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, ...
                'FontName', PTKSoftwareInfo.GuiFont, 'FontSize', 20.0, 'ForegroundColor', [1.0 0.694 0.392], 'HorizontalAlignment', 'left', ...
                'FontWeight', 'bold');
            obj.TextVersionHandle = uicontrol('Parent', obj.GraphicalComponentHandle, 'Style', 'text', ...
                'Units', 'pixels', 'Position', text_position, 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, ...
                'FontName', PTKSoftwareInfo.GuiFont, 'FontSize', 20.0, 'ForegroundColor', [1.0 0.694 0.392], 'HorizontalAlignment', 'left', ...
                'FontWeight', 'bold', 'String', obj.GetSoftwareNameAndVersionForDisplay);
            obj.ProfileCheckboxHandle = uicontrol('Parent', obj.GraphicalComponentHandle, 'Style', 'checkbox', 'String', 'Enable profiler', ...
                'Units', 'pixels', 'Position', profile_checkbox_position, 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'ForegroundColor', [1 1 1], ...
                'Callback', @obj.ProfileCheckboxCallback);
            
            % Update the profile checkbox with the current status of the Matlab
            % profilers
            obj.UpdateProfilerStatus;            
        end
        
        function Resize(obj, panel_position)
            Resize@PTKPanel(obj, panel_position);
            
            text_width = panel_position(3) - obj.LeftMargin - obj.RightMargin - obj.HorizontalSpacing - obj.ProfileCheckboxWidth;
            text_width = max(obj.MinimumTextWidth, text_width);
            checkbox_pos = obj.LeftMargin + text_width + obj.HorizontalSpacing;
            checkbox_width = panel_position(3) - checkbox_pos;
            
            blank_text_position = [1, 1, panel_position(3), panel_position(4)];
            text_position = [obj.LeftMargin, 1, panel_position(3), panel_position(4)];
            profile_checkbox_position = [checkbox_pos, 1, checkbox_width, panel_position(4)];
            
            if ~isempty(obj.TextBlankHandle)
                set(obj.TextBlankHandle, 'Position', blank_text_position);
                set(obj.TextVersionHandle, 'Position', text_position);
                set(obj.ProfileCheckboxHandle, 'Position', profile_checkbox_position);
            end
            
        end
        
        
    end
    
    methods (Access = private)
        % Profile checkbox
        % Enables or disables (and shows) Matlab's profiler
        function ProfileCheckboxCallback(obj, hObject, ~, ~)
            if get(hObject,'Value')
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
                set(obj.ProfileCheckboxHandle, 'Value', true);
            else
                set(obj.ProfileCheckboxHandle, 'Value', false);
            end
        end
        
        
    end
end