classdef PTKViewerPanelToolbar < PTKPanel
    % PTKViewerPanelToolbar. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKViewerPanelToolbar is used to build the controls for the PTKViewingPanel
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        ViewerPanel
        
        Tools
        
        % Handler to listener for when the mouse status changes
        MouseCursorStatusListener
        
        % User interface controls
        OrientationPanel
        MouseControlPanel
        ImageOverlayPanel
        WindowLevelPanel
        OrientationButtons
        OpacitySlider
        ImageCheckbox
        OverlayCheckbox
        StatusText
        WindowText
        WindowEditbox
        WindowSlider
        LevelText
        LevelEditbox
        LevelSlider
        MouseControlButtons
    end
    
    methods
        function obj = PTKViewerPanelToolbar(viewer_panel, tools, reporting)
            obj = obj@PTKPanel(viewer_panel, reporting);
            obj.ViewerPanel = viewer_panel;
            obj.BackgroundColour = 'black';
            obj.Tools = tools;
            
            tools.SetToolbar(obj);
            
            obj.MouseCursorStatusListener = addlistener(obj.ViewerPanel, 'MouseCursorStatusChanged', @obj.MouseCursorStatusChangedCallback);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKPanel(obj, position, reporting);
            
            parent = obj.GetParentFigure;
            keypress_function = @parent.CustomKeyPressedFunction;
            
            font_size = 9;
            
            % Buttons for coronal/sagittal/axial views
            obj.OrientationPanel = uibuttongroup('Parent', obj.Parent.GetContainerHandle(reporting), 'Units', 'pixels', 'BorderType', 'none', 'SelectionChangeFcn', @obj.OrientationCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            orientation_buttons = [0 0 0];
            orientation_buttons(1) = uicontrol('Style', 'togglebutton', 'Units', 'pixels', 'Parent', obj.OrientationPanel, 'String', 'Cor', 'Units', 'pixels', 'FontSize', font_size, 'Tag', 'Coronal', 'TooltipString', 'View coronal slices (Y-Z)', 'KeyPressFcn', keypress_function);
            orientation_buttons(2) = uicontrol('Style', 'togglebutton', 'Units', 'pixels', 'Parent', obj.OrientationPanel, 'String', 'Sag', 'Units', 'pixels', 'FontSize', font_size, 'Tag', 'Sagittal', 'TooltipString', 'View sagittal slices (X-Z)', 'KeyPressFcn', keypress_function);
            orientation_buttons(3) = uicontrol('Style', 'togglebutton', 'Units', 'pixels', 'Parent', obj.OrientationPanel, 'String', 'Ax', 'Units', 'pixels', 'FontSize', font_size, 'Tag', 'Axial', 'TooltipString', 'View transverse slices (X-Y)', 'KeyPressFcn', keypress_function);
            obj.OrientationButtons = orientation_buttons;
            set(obj.OrientationButtons(obj.ViewerPanel.Orientation), 'Value', 1);
            
            % Buttons for each mouse tool
            obj.MouseControlPanel = uibuttongroup('Parent', obj.Parent.GetContainerHandle(reporting), 'Units', 'pixels', 'BorderType', 'none', 'SelectionChangeFcn', @obj.ControlsCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            obj.MouseControlButtons = containers.Map;
            for tool_set = obj.Tools.Tools.values
                tool = tool_set{1};
                tag = tool.Tag;
                obj.MouseControlButtons(tag) = uicontrol('Style', 'togglebutton', 'Units', 'pixels', 'Parent', obj.MouseControlPanel, 'String', tool.ButtonText, 'Units', 'pixels', 'FontSize', font_size, 'Tag', tool.Tag, 'TooltipString', tool.ToolTip, 'KeyPressFcn', keypress_function);
            end
            set(obj.MouseControlButtons(obj.ViewerPanel.SelectedControl), 'Value', 1);
            
            obj.WindowLevelPanel = uipanel('Parent', obj.Parent.GetContainerHandle(reporting), 'Units', 'pixels', 'BorderType', 'none', 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            obj.ImageOverlayPanel = uipanel('Parent', obj.Parent.GetContainerHandle(reporting), 'Units', 'pixels', 'BorderType', 'none', 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            
            obj.StatusText = uicontrol('Style', 'text', 'Parent', obj.ImageOverlayPanel, 'Units', 'pixels', 'FontSize', font_size, 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            
            obj.OpacitySlider = uicontrol('Style', 'slider', 'Parent', obj.ImageOverlayPanel, 'Units', 'pixels', 'Callback', @obj.OpacitySliderCallback, 'TooltipString', 'Change opacity of overlay', 'Min', 0, 'Max', 100, 'KeyPressFcn', keypress_function, 'Value', obj.ViewerPanel.OverlayOpacity);
            obj.ImageCheckbox = uicontrol('Style', 'checkbox', 'Parent', obj.ImageOverlayPanel, 'Units', 'pixels', 'FontSize', font_size, 'Callback', @obj.ImageCheckboxCallback, 'String', 'Image', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Show image', 'KeyPressFcn', keypress_function, 'Value', obj.ViewerPanel.ShowImage);
            obj.OverlayCheckbox = uicontrol('Style', 'checkbox', 'Parent', obj.ImageOverlayPanel, 'Units', 'pixels', 'FontSize', font_size, 'Callback', @obj.OverlayCheckboxCallback, 'String', 'Overlay', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Show overlay over image', 'KeyPressFcn', keypress_function, 'Value', obj.ViewerPanel.ShowOverlay);
            
            obj.WindowText = uicontrol('Style', 'text', 'Parent', obj.WindowLevelPanel, 'Units', 'pixels', 'FontSize', font_size, 'String', 'Window:', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'HorizontalAlignment', 'right');
            obj.LevelText = uicontrol('Style', 'text', 'Parent', obj.WindowLevelPanel, 'Units', 'pixels', 'FontSize', font_size, 'String', 'Level:', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'HorizontalAlignment', 'right');
            obj.WindowEditbox = uicontrol('Style', 'edit', 'Parent', obj.WindowLevelPanel, 'Units', 'pixels', 'FontSize', font_size, 'Callback', @obj.WindowTextCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Change window (contrast)', 'String', num2str(obj.ViewerPanel.Window));
            obj.LevelEditbox = uicontrol('Style', 'edit', 'Parent', obj.WindowLevelPanel, 'Units', 'pixels', 'FontSize', font_size, 'Callback', @obj.LevelTextCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Change level (brightness)', 'String', num2str(obj.ViewerPanel.Level));
            obj.WindowSlider = uicontrol('Style', 'slider', 'Units', 'pixels', 'Min', 0, 'Max', 1, 'Value', 1, 'Parent', obj.WindowLevelPanel, 'Callback', @obj.WindowSliderCallback, 'TooltipString', 'Change window (contrast)', 'KeyPressFcn', keypress_function, 'Value', obj.ViewerPanel.Window);
            obj.LevelSlider = uicontrol('Style', 'slider', 'Units', 'pixels', 'Min', 0, 'Max', 1, 'Value', 0, 'Parent', obj.WindowLevelPanel, 'Callback', @obj.LevelSliderCallback, 'TooltipString', 'Change level (brightness)', 'KeyPressFcn', keypress_function, 'Value', obj.ViewerPanel.Level);
            
            % Add context menu
            obj.Tools.UpdateTools;
            
            % Add custom listeners to allow continuous callbacks from the
            % sliders
            obj.AddEventListener(obj.OpacitySlider, 'ContinuousValueChange', @obj.OpacitySliderCallback);
            obj.AddEventListener(obj.WindowSlider, 'ContinuousValueChange', @obj.WindowSliderCallback);
            obj.AddEventListener(obj.LevelSlider, 'ContinuousValueChange', @obj.LevelSliderCallback);
            
            obj.ResizePanel(position);
        end
        
        function delete(obj)
            delete(obj.MouseCursorStatusListener);
        end
        
        function Resize(obj, position)
            Resize@PTKPanel(obj, position);
            
            if obj.ComponentHasBeenCreated
                obj.ResizePanel(position);
            end
        end
        
        function UpdateWindowLimits(obj)
            % Sets the minimum and maximum values for the window slider
            
            window_limits = obj.ViewerPanel.WindowLimits;
            if ~isempty(window_limits)
                set(obj.WindowSlider, 'Min', window_limits(1), 'Max', window_limits(2));
            end
            
        end
        
        function UpdateLevelLimits(obj)
            % Sets the minimum and maximum values for the level slider
            
            level_limits = obj.ViewerPanel.LevelLimits;
            if ~isempty(level_limits)
                set(obj.LevelSlider, 'Min', level_limits(1), 'Max', level_limits(2));
            end
        end
        
        function SetControl(obj, tag_value)
            % Enable the button for this tool
            set(obj.MouseControlButtons(tag_value), 'Value', 1);
        end
        
        function UpdateGui(obj, main_image)
            if obj.ComponentHasBeenCreated
                set(obj.OverlayCheckbox, 'Value', obj.ViewerPanel.ShowOverlay);
                set(obj.ImageCheckbox, 'Value', obj.ViewerPanel.ShowImage);
                set(obj.OrientationButtons(obj.ViewerPanel.Orientation), 'Value', 1);
                set(obj.MouseControlButtons(obj.ViewerPanel.SelectedControl), 'Value', 1);
                
                if ~isempty(main_image) && main_image.ImageExists
                    set(obj.WindowEditbox, 'String', num2str(obj.ViewerPanel.Window));
                    set(obj.WindowSlider, 'Value', obj.ViewerPanel.Window);
                    set(obj.LevelEditbox, 'String', num2str(obj.ViewerPanel.Level));
                    set(obj.LevelSlider, 'Value', obj.ViewerPanel.Level);
                    set(obj.OpacitySlider, 'Value', obj.ViewerPanel.OverlayOpacity);
                end
            end
        end
    end
    
    methods (Access = private)
        
        function MouseCursorStatusChangedCallback(obj, ~, ~)
            mouse_cursor_status = obj.ViewerPanel.MouseCursorStatus;
            orientation = obj.ViewerPanel.Orientation;
            
            if ~mouse_cursor_status.ImageExists
                status_text = 'No image';
            else
                rescale_text = '';
                
                i_text = int2str(mouse_cursor_status.GlobalCoordX);
                j_text = int2str(mouse_cursor_status.GlobalCoordY);
                k_text = int2str(mouse_cursor_status.GlobalCoordZ);
                
                if ~isempty(mouse_cursor_status.ImageValue)
                    voxel_value = mouse_cursor_status.ImageValue;
                    if isinteger(voxel_value)
                        value_text = int2str(voxel_value);
                    else
                        value_text = num2str(voxel_value, 3);
                    end
                    
                    rescaled_value = mouse_cursor_status.RescaledValue;
                    rescale_units = mouse_cursor_status.RescaleUnits;
                    if ~isempty(rescale_units) && ~isempty(rescaled_value)
                        rescale_text = [rescale_units ':' int2str(rescaled_value)];
                    end
                    
                    if isempty(mouse_cursor_status.OverlayValue)
                        overlay_text = [];
                    else
                        overlay_value = mouse_cursor_status.OverlayValue;
                        if isinteger(overlay_value)
                            overlay_value_text = int2str(overlay_value);
                        else
                            overlay_value_text = num2str(overlay_value, 3);
                        end
                        overlay_text = [' O:' overlay_value_text];
                    end
                else
                    overlay_text = '';
                    value_text = '-';
                    switch orientation
                        case PTKImageOrientation.Coronal
                            j_text = '--';
                            k_text = '--';
                        case PTKImageOrientation.Sagittal
                            i_text = '--';
                            k_text = '--';
                        case PTKImageOrientation.Axial
                            i_text = '--';
                            j_text = '--';
                    end
                    
                end
                
                status_text = ['X:' j_text ' Y:' i_text ' Z:' k_text ' I:' value_text ' ' rescale_text overlay_text];
            end
            
            obj.SetStatus(status_text);
        end
        
        function ResizePanel(obj, position)
            panel_width_pixels = position(3);
            panel_height_pixels = position(4);
            
            button_width = 32;
            
            number_of_enabled_control_buttons = 0;
            
            for tool_tag = obj.MouseControlButtons.keys
                button = obj.MouseControlButtons(tool_tag{1});
                tool = obj.Tools.GetTool(tool_tag{1});
                if tool.IsEnabled(obj.ViewerPanel.Mode, obj.ViewerPanel.SubMode)
                    number_of_enabled_control_buttons = number_of_enabled_control_buttons + 1;
                    set(button, 'Units', 'Pixels', 'Position', [1+button_width*(number_of_enabled_control_buttons - 1), 1, button_width, button_width], 'Visible', 'on');
                else
                    set(button, 'Visible', 'off');
                end
            end
            
            orientation_width = numel(obj.OrientationButtons)*button_width;
            mouse_controls_width = (number_of_enabled_control_buttons)*button_width;
            mouse_controls_position = panel_width_pixels - mouse_controls_width + 1;
            central_panels_width = max(1, (panel_width_pixels - mouse_controls_width - orientation_width)/2);
            windowlevel_panel_position = orientation_width + central_panels_width + 1;
            set(obj.MouseControlPanel, 'Units', 'Pixels', 'Position', [mouse_controls_position 1 mouse_controls_width panel_height_pixels]);
            set(obj.ImageOverlayPanel, 'Units', 'Pixels', 'Position', [orientation_width+1 1 central_panels_width panel_height_pixels]);
            set(obj.WindowLevelPanel, 'Units', 'Pixels', 'Position', [windowlevel_panel_position 1 central_panels_width panel_height_pixels]);
            
            % Setup orientation panel
            set(obj.OrientationPanel, 'Units', 'Pixels', 'Position', [1 1 orientation_width panel_height_pixels]);
            set(obj.OrientationButtons(1), 'Units', 'Pixels', 'Position', [1 1 button_width  button_width]);
            set(obj.OrientationButtons(2), 'Units', 'Pixels', 'Position', [1+button_width 1 button_width button_width]);
            set(obj.OrientationButtons(3), 'Units', 'Pixels', 'Position', [1+button_width*2 1 button_width button_width]);
            
            % Setup image/overlay panel
            halfpanel_height = 16;
            checkbox_width = 70;
            status_width = max(1, central_panels_width - checkbox_width);
            set(obj.ImageCheckbox, 'Units', 'Pixels', 'Position', [1 1+halfpanel_height checkbox_width halfpanel_height]);
            set(obj.StatusText, 'Units', 'Pixels', 'Position', [1+checkbox_width halfpanel_height status_width halfpanel_height]);
            set(obj.OverlayCheckbox, 'Units', 'Pixels', 'Position', [1 1 checkbox_width halfpanel_height]);
            set(obj.OpacitySlider, 'Units', 'Pixels', 'Position', [checkbox_width 1 status_width halfpanel_height]);
            
            % Setup window/level panel
            windowlevel_text_width = 60;
            windowlevel_editbox_width = 60;
            windowlevel_editbox_height = 19;
            windowlevel_slider_width = max(1, central_panels_width - windowlevel_text_width - windowlevel_editbox_width);
            windowlevel_editbox_position =  1+windowlevel_text_width;
            windowlevel_slider_position = 1+windowlevel_text_width + windowlevel_editbox_width;
            set(obj.LevelText, 'Units', 'Pixels', 'Position', [1 0 windowlevel_text_width halfpanel_height]);
            set(obj.LevelEditbox, 'Units', 'Pixels', 'Position', [windowlevel_editbox_position 0 windowlevel_editbox_width windowlevel_editbox_height]);
            set(obj.LevelSlider, 'Units', 'Pixels', 'Position', [windowlevel_slider_position 1 windowlevel_slider_width halfpanel_height]);
            set(obj.WindowText, 'Units', 'Pixels', 'Position', [1 halfpanel_height windowlevel_text_width halfpanel_height]);
            set(obj.WindowEditbox, 'Units', 'Pixels', 'Position', [windowlevel_editbox_position halfpanel_height-1 windowlevel_editbox_width windowlevel_editbox_height]);
            set(obj.WindowSlider, 'Units', 'Pixels', 'Position', [windowlevel_slider_position 1+halfpanel_height windowlevel_slider_width halfpanel_height]);
        end
        
        function SetStatus(obj, status_text)
            set(obj.StatusText, 'String', status_text);
        end
        
        function ImageCheckboxCallback(obj, hObject, ~, ~)
            % Called when show image checkbox is changed
            obj.ViewerPanel.ShowImage = get(hObject, 'Value');
        end
        
        function OverlayCheckboxCallback(obj, hObject, ~, ~)
            % Called when show overlay checkbox is changed
            obj.ViewerPanel.ShowOverlay = get(hObject, 'Value');
        end
        
        function WindowSliderCallback(obj, hObject, ~, ~)
            % Window slider
            obj.ViewerPanel.Window = round(get(hObject,'Value'));
        end
        
        function LevelSliderCallback(obj, hObject, ~, ~)
            % Level slider
            obj.ViewerPanel.Level = round(get(hObject,'Value'));
        end
        
        function WindowTextCallback(obj, hObject, ~, ~)
            % Window edit box
            obj.ViewerPanel.Window = round(str2double(get(hObject,'String')));
        end
        
        function LevelTextCallback(obj, hObject, ~, ~)
            % Level edit box
            obj.ViewerPanel.Level = round(str2double(get(hObject,'String')));
        end
        
        function OrientationCallback(obj, ~, eventdata, ~)
            % Coronal/sagittal/axial orientation
            switch get(eventdata.NewValue, 'Tag')
                case 'Coronal'
                    obj.ViewerPanel.Orientation = PTKImageOrientation.Coronal;
                case 'Sagittal'
                    obj.ViewerPanel.Orientation = PTKImageOrientation.Sagittal;
                case 'Axial'
                    obj.ViewerPanel.Orientation = PTKImageOrientation.Axial;
            end
        end
        
        function ControlsCallback(obj, ~, eventdata, ~)
            % New tool selected
            obj.ViewerPanel.SetControl(get(eventdata.NewValue, 'Tag'));
        end
        
        function OpacitySliderCallback(obj, hObject, ~, ~)
            % The slider controlling the opacity of the transparent overlay
            
            obj.ViewerPanel.OverlayOpacity = get(hObject,'Value');
        end
        
    end
end