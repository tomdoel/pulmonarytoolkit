classdef TDViewerPanel < handle
    % TDViewerPanel. Creates a data viewer window for imaging 3D data slice-by-slice.
    %
    %     TDViewerPanel creates a visualisation window on the supplied
    %     graphics handle. It creates the viewer panel, scrollbar, orientation
    %     and tool controls, a status window and controls for toggling the image
    %     and overlay on and off and changing overlay transparency.
    %
    %     TDViewerPanel is used as a component by the standalong data viewer
    %     application TDViewer, and by the Pulmonary Toolkit gui application.
    %     You can also use this in your own user interfaces.
    %
    %     New background, overlay and quiver plots can be viewed by assigning
    %     images (within a TDViewer class) to the BackgroundImage, OverlayImage
    %     and QuiverImage properties.
    %
    %     To set the marker image, use MarkerPointManager.ChangeMarkerImage
    %
    %     See TDViewer.m for a simple example of how to use this class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (SetObservable)
        Orientation = TDImageOrientation.Coronal
        OverlayOpacity = 50
        ShowImage = true
        ShowOverlay = true
        BlackIsTransparent = true
        Window = 1000
        Level = 1000
        SliceNumber = [1 1 1]
        SliceSkip = 10
        BackgroundImage
        OverlayImage
        QuiverImage
    end
    
    properties
        MarkerPointManager
    end
    
    events
        MarkerPanelSelected
    end

    properties (Access = private)
        FigureHandle
        CandidatePoints
        CursorIsACross = false
        m_parent
        image_handles = {[], [], []} % Handles to image and overlay
        SelectedControl = 4 % The number of the selected button in the controls panel
        
        % Gui elements
        m_control_panel;
        m_imageoverlay_panel;
        m_windowlevel_panel;
        m_axes;
        m_slice_slider;
        m_orientation_panel;
        m_orientation_buttons;
        m_opacity_slider;
        m_image_checkbox;
        m_overlay_checkbox;
        m_status_text;
        m_window_text;
        m_window_editbox;
        m_window_slider;
        m_level_text;
        m_level_editbox;
        m_level_slider;
        m_mouse_control_panel;
        m_mouse_control_buttons;
        
        m_axis_limits;
        m_previous_orientation;

        % Callbacks
        m_resize_fcn;
        m_WindowButtonMotionFcn;
        
        % Handles to listeners for image changes
        image_changed_listeners = {[], [], []}
        
        % Used for programmatic pan, zoom, etc.
        m_last_coordinates = [0, 0, 0]
        m_mouse_down = false
    end
    
    events
        MouseClickInImage
    end
    
    methods
        function obj = TDViewerPanel(parent)
            font_size = 10;
            obj.m_axis_limits = [];
            obj.m_axis_limits{1} = {};
            obj.m_axis_limits{2} = {};
            obj.m_axis_limits{3} = {};
            
            % These must be created here, not on the properties section, to
            % prevent Matlab creating a circular dependency (see Matlab solution 1-6K9BQ7)
            obj.BackgroundImage = TDImage;
            obj.OverlayImage = TDImage;
            obj.QuiverImage = TDImage;

            
            obj.m_parent = parent;
            
            obj.m_slice_slider = uicontrol('Style', 'slider', 'Parent', obj.m_parent, 'TooltipString', 'Scroll through slices');
            obj.m_axes = axes('Parent', obj.m_parent);
            
            obj.MarkerPointManager = TDMarkerPointManager(obj, obj.m_axes);

            obj.m_control_panel = uipanel('Parent', obj.m_parent, 'BorderType', 'none', 'BackgroundColor', 'black', 'ForegroundColor', 'white');

            obj.m_orientation_panel = uibuttongroup('Parent', obj.m_control_panel, 'BorderType', 'none', 'SelectionChangeFcn', @obj.OrientationCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            obj.m_mouse_control_panel = uibuttongroup('Parent', obj.m_control_panel, 'BorderType', 'none', 'SelectionChangeFcn', @obj.ControlsCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            
            orientation_buttons = [0 0 0];
            orientation_buttons(1) = uicontrol('Style', 'togglebutton', 'Parent', obj.m_orientation_panel, 'String', 'Cor', 'FontSize', font_size, 'Tag', 'Coronal', 'TooltipString', 'View coronal slices (Y-Z)');
            orientation_buttons(2) = uicontrol('Style', 'togglebutton', 'Parent', obj.m_orientation_panel, 'String', 'Sag', 'FontSize', font_size, 'Tag', 'Sagittal', 'TooltipString', 'View sagittal slices (X-Z)');
            orientation_buttons(3) = uicontrol('Style', 'togglebutton', 'Parent', obj.m_orientation_panel, 'String', 'Ax', 'FontSize', font_size, 'Tag', 'Axial', 'TooltipString', 'View transverse slices (X-Y)');
            obj.m_orientation_buttons = orientation_buttons;
            
            control_buttons = [0 0 0];
            control_buttons(1) = uicontrol('Style', 'togglebutton', 'Parent', obj.m_mouse_control_panel, 'String', 'Zoom', 'FontSize', font_size, 'Tag', 'Zoom', 'TooltipString', 'Zoom tool');
            control_buttons(2) = uicontrol('Style', 'togglebutton', 'Parent', obj.m_mouse_control_panel, 'String', 'Pan', 'FontSize', font_size, 'Tag', 'Pan', 'TooltipString', 'Pan tool');
            control_buttons(3) = uicontrol('Style', 'togglebutton', 'Parent', obj.m_mouse_control_panel, 'String', 'Mark', 'FontSize', font_size, 'Tag', 'Mark', 'TooltipString', 'Select point');
            control_buttons(4) = uicontrol('Style', 'togglebutton', 'Parent', obj.m_mouse_control_panel, 'String', 'W/L', 'FontSize', font_size, 'Tag', 'W/L', 'TooltipString', 'Window/level tool. Drag mouse to change window and level.');
            control_buttons(5) = uicontrol('Style', 'togglebutton', 'Parent', obj.m_mouse_control_panel, 'String', 'Cine', 'FontSize', font_size, 'Tag', 'Cine', 'TooltipString', 'Cine tool. Drag mouse to cine through slices');
            obj.m_mouse_control_buttons = control_buttons;

            obj.m_windowlevel_panel = uipanel('Parent', obj.m_control_panel, 'BorderType', 'none', 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            obj.m_imageoverlay_panel = uipanel('Parent', obj.m_control_panel, 'BorderType', 'none', 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            
            obj.m_status_text = uicontrol('Style', 'text', 'Parent', obj.m_imageoverlay_panel, 'FontSize', font_size, 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            
            obj.m_opacity_slider = uicontrol('Style', 'slider', 'Parent', obj.m_imageoverlay_panel, 'Callback', @obj.OpacitySliderCallback, 'TooltipString', 'Change opacity of overlay');
            obj.m_image_checkbox = uicontrol('Style', 'checkbox', 'Parent', obj.m_imageoverlay_panel, 'FontSize', font_size, 'Callback', @obj.ImageCheckboxCallback, 'String', 'Image', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Show image');
            obj.m_overlay_checkbox = uicontrol('Style', 'checkbox', 'Parent', obj.m_imageoverlay_panel, 'FontSize', font_size, 'Callback', @obj.OverlayCheckboxCallback, 'String', 'Overlay', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Show overlay over image');
          
            obj.m_window_text = uicontrol('Style', 'text', 'Parent', obj.m_windowlevel_panel, 'FontSize', font_size, 'String', 'Window:', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'HorizontalAlignment', 'right');
            obj.m_level_text = uicontrol('Style', 'text', 'Parent', obj.m_windowlevel_panel, 'FontSize', font_size, 'String', 'Level:', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'HorizontalAlignment', 'right');
            obj.m_window_editbox = uicontrol('Style', 'edit', 'Parent', obj.m_windowlevel_panel, 'FontSize', font_size, 'Callback', @obj.WindowTextCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Change window (contrast)');
            obj.m_level_editbox = uicontrol('Style', 'edit', 'Parent', obj.m_windowlevel_panel, 'FontSize', font_size, 'Callback', @obj.LevelTextCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Change level (brightness)');
            obj.m_window_slider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 1, 'Value', 1, 'Parent', obj.m_windowlevel_panel, 'Callback', @obj.WindowSliderCallback, 'TooltipString', 'Change window (contrast)');
            obj.m_level_slider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 1, 'Value', 0, 'Parent', obj.m_windowlevel_panel, 'Callback', @obj.LevelSliderCallback, 'TooltipString', 'Change level (brightness)');
            
            obj.m_resize_fcn = get(parent, 'ResizeFcn');
            
            figure_handle = ancestor(parent, 'figure');
            obj.FigureHandle = figure_handle;
            obj.m_WindowButtonMotionFcn = get(figure_handle, 'WindowButtonMotionFcn');
            
            obj.UpdateGui;
            obj.UpdateStatus;
            obj.Resize;
            
            hold(obj.m_axes, 'on');

            set(parent, 'ResizeFcn', @obj.CustomResize);
            set(figure_handle, 'WindowButtonMotionFcn', @obj.MouseHasMoved);
            set(figure_handle, 'WindowButtonUpFcn', @obj.MouseUp);
            set(figure_handle, 'WindowButtonDownFcn', @obj.MouseDown);
            set(figure_handle, 'WindowScrollWheelFcn', @obj.WindowScrollWheelFcn);
            set(figure_handle, 'KeyPressFcn', @obj.KeyPressed);
            

            obj.CaptureKeyboardInput(figure_handle);
            
            
            % Add custom listeners to allow continuous callbacks from the
            % sliders
            setappdata(parent ,'sliderListeners', handle.listener(obj.m_slice_slider, 'ActionEvent', @obj.SliderCallback));
            setappdata(obj.m_imageoverlay_panel, 'sliderListenersO', handle.listener(obj.m_opacity_slider, 'ActionEvent', @obj.OpacitySliderCallback));
            setappdata(obj.m_windowlevel_panel, 'sliderListenersW', handle.listener(obj.m_window_slider, 'ActionEvent', @obj.WindowSliderCallback));
            setappdata(obj.m_windowlevel_panel, 'sliderListenersL', handle.listener(obj.m_level_slider, 'ActionEvent', @obj.LevelSliderCallback));
            
            % Change in orientation requires a redraw of axes
            addlistener(obj, 'Orientation', 'PostSet', @obj.OrientationChangedCallback);
            
            % Other changes require redraw of gui
            addlistener(obj, 'SliceNumber', 'PostSet', @obj.SliceNumberChangedCallback);
            addlistener(obj, 'Level', 'PostSet', @obj.SettingsChangedCallback);
            addlistener(obj, 'Window', 'PostSet', @obj.SettingsChangedCallback);
            addlistener(obj, 'OverlayOpacity', 'PostSet', @obj.SettingsChangedCallback);
            addlistener(obj, 'ShowImage', 'PostSet', @obj.SettingsChangedCallback);
            addlistener(obj, 'ShowOverlay', 'PostSet', @obj.SettingsChangedCallback);            
            addlistener(obj, 'BlackIsTransparent', 'PostSet', @obj.SettingsChangedCallback);            
                                    
            % Listen for image change events
            addlistener(obj, 'BackgroundImage', 'PostSet', @obj.ImagePointerChangedCallback);
            obj.SetImage(obj.BackgroundImage);
            addlistener(obj, 'OverlayImage', 'PostSet', @obj.OverlayImagePointerChangedCallback);
            obj.SetOverlayImage(obj.OverlayImage);
            addlistener(obj, 'QuiverImage', 'PostSet', @obj.QuiverImagePointerChangedCallback);
            obj.SetQuiverImage(obj.QuiverImage);
            
            obj.MarkerPointManager.Enable(obj.SelectedControl == 3);
        end

        function RestoreKeyPressCallback(obj)
            % For the zoom and pan tools, we need to disable the Matlab fuctions
            % that prevent custom keyboard callbacks being used; otherwise our
            % keyboard shortcuts will be sent to the command line
            hManager = uigetmodemanager(obj.FigureHandle);
            set(hManager.WindowListenerHandles, 'Enable', 'off');
            set(obj.FigureHandle, 'KeyPressFcn', @obj.KeyPressed);
        end

        function EnterFcn(~, figHandle, ~)
            set(figHandle, 'Pointer', 'fleur');
        end
        
        function GetFocus(obj)
            figure(obj.FigureHandle);
        end
        
        function CaptureKeyboardInput(obj, figure_handle)
            controls = findobj(figure_handle, 'Style','pushbutton', '-or', 'Style', 'checkbox', '-or', 'Style', 'togglebutton', '-or', 'Style', 'text', '-or', 'Style', 'slider');
            for control = controls
                set(control, 'KeyPressFcn', @obj.KeyPressed);
            end
        end
        
        function ClearOverlays(obj)
            obj.OverlayImage.Title = [];
            obj.OverlayImage.Reset;
            obj.QuiverImage.Reset;
        end
        
        function in_marker_mode = IsInMarkerMode(obj)
            in_marker_mode = obj.SelectedControl == 3;
        end
    end
    
    
    methods (Access=private)
        function SetImage(obj, new_image)
            obj.AddImage(1, new_image);
        end
        
        function SetOverlayImage(obj, overlay_image)
            obj.AddImage(2, overlay_image);
        end
        
        function SetQuiverImage(obj, quiver_image)
            obj.AddImage(3, quiver_image);
        end
        
        function ImagePointerChanged(obj, ~)
            obj.AddImage(1, obj.BackgroundImage);
        end
        
        function OverlayImagePointerChanged(obj, ~)
            obj.AddImage(2, obj.OverlayImage);
        end
        
        function QuiverImagePointerChanged(obj, ~)
            obj.AddImage(3, obj.QuiverImage);
        end
                
        function AddImage(obj, image_number, new_image)
            % Check that this image is the correct class type
            if ~isa(new_image, 'TDImage')
                error('The image must be of class TDImage');                
            end
            
            no_current_image = isempty(obj.image_handles{image_number});

            % Create an image handle if one doesn't already exist
            if isempty(obj.image_handles{image_number})
                if (image_number == 3)
                    obj.image_handles{image_number} = quiver([], [], [], [], 'Parent', obj.m_axes, 'Color', 'red');  
                else
                      obj.image_handles{image_number} = image([], 'Parent', obj.m_axes);
                      axis(obj.m_axes, 'off');
                      set(obj.m_axes, 'YDir', 'reverse');
                end
            end
            
            % Update the panel
            if (image_number == 1 || no_current_image) % We need to set the axes initially, otherwise the overlay will not appear until UpdateAxes is called
                obj.ImageChanged;
            else                
                obj.OverlayImageChanged;
            end
            
            % Remove existing listeners
            if ~isempty(obj.image_changed_listeners{image_number})
                delete (obj.image_changed_listeners{image_number})
            end
            
            % Listen for image change events
            if (image_number == 1)
                obj.image_changed_listeners{image_number} = addlistener(new_image, 'ImageChanged', @obj.ImageChangedCallback);
            else                
                obj.image_changed_listeners{image_number} = addlistener(new_image, 'ImageChanged', @obj.OverlayImageChangedCallback);
            end
        end
        
        function UpdateAxes(obj)
            if (obj.BackgroundImage.ImageExists)                
                if ~isempty(obj.m_previous_orientation)
                    x_lim = get(obj.m_axes, 'XLim');
                    y_lim = get(obj.m_axes, 'YLim');
                    obj.m_axis_limits{obj.m_previous_orientation}.XLim = x_lim;
                    obj.m_axis_limits{obj.m_previous_orientation}.YLim = y_lim;
                end
                set(obj.m_axes, 'Units', 'pixels');
                axes_position = get(obj.m_axes, 'Position');
                axes_width_screenpixels = axes_position(3);
                axes_height_screenpixels = axes_position(4);
                image_size = obj.BackgroundImage.ImageSize;
                voxel_size = obj.BackgroundImage.VoxelSize;
                
                [dim_x_index, dim_y_index, dim_z_index] = GetXYDimensionIndex(obj);
                x_range = [1, image_size(dim_x_index)];
                y_range = [1, image_size(dim_y_index)];
                pixel_ratio = [voxel_size(dim_y_index) voxel_size(dim_x_index) voxel_size(dim_z_index)];
                image_height_mm = voxel_size(dim_y_index).*image_size(dim_y_index);
                image_width_mm = voxel_size(dim_x_index).*image_size(dim_x_index);
                
                screenpixels_per_mm = axes_width_screenpixels/image_width_mm;
                rescaled_height_screenpixels = image_height_mm*screenpixels_per_mm;
                if rescaled_height_screenpixels <= axes_height_screenpixels
                    scale_to_x = true;
                else
                    scale_to_x = false;
                end

                if (scale_to_x)
                    screenpixels_per_mm = axes_width_screenpixels./image_width_mm;
                    rescaled_height_screenpixels = image_height_mm.*screenpixels_per_mm;
                    vertical_space_screenpixels = (axes_height_screenpixels - rescaled_height_screenpixels)/2;
                    vertical_space_mm = vertical_space_screenpixels./screenpixels_per_mm;
                    vertical_space_pixels = vertical_space_mm./pixel_ratio(1);
                    x_lim = [x_range(1) - 0.5, x_range(2) + 0.5];
                    y_lim = [y_range(1) - vertical_space_pixels - 0.5, y_range(2) + vertical_space_pixels + 0.5];
                else
                    screenpixels_per_mm = axes_height_screenpixels./image_height_mm;
                    rescaled_width_screenpixels = image_width_mm.*screenpixels_per_mm;
                    horizontal_space_screenpixels = (axes_width_screenpixels - rescaled_width_screenpixels)/2;
                    horizontal_space_mm = horizontal_space_screenpixels./screenpixels_per_mm;
                    horizontal_space_pixels = horizontal_space_mm./pixel_ratio(2);
                    x_lim = [x_range(1) - horizontal_space_pixels - 0.5, x_range(2) + horizontal_space_pixels + 0.5];
                    y_lim = [y_range(1) - 0.5, y_range(2) + 0.5];
                end
                 
                data_aspect_ratio = 1./[pixel_ratio(2) pixel_ratio(1) pixel_ratio(3)];
                set(obj.m_axes, 'XLim', x_lim, 'YLim', y_lim, 'DataAspectRatio', data_aspect_ratio);

                
                zoom(obj.m_axes, 'reset');                
                if ~isempty(obj.m_previous_orientation) && ~isempty(obj.m_axis_limits{obj.Orientation})
                    x_lim = obj.m_axis_limits{obj.Orientation}.XLim;
                    y_lim = obj.m_axis_limits{obj.Orientation}.YLim;
                    set(obj.m_axes, 'XLim', x_lim, 'YLim', y_lim);
                end
                obj.m_previous_orientation = obj.Orientation;

                if ~isempty(obj.image_handles{1})
                    set(obj.image_handles{1}, 'XData', x_range, 'YData', y_range);
                end
                if ~isempty(obj.image_handles{2})
                    set(obj.image_handles{2}, 'XData', x_range, 'YData', y_range);
                end
                if ~isempty(obj.image_handles{3})
                    set(obj.image_handles{3}, 'XData', x_range, 'YData', y_range);
                end
            end
        end
        
        function [dim_x_index dim_y_index dim_z_index] = GetXYDimensionIndex(obj)
            switch obj.Orientation
                case TDImageOrientation.Coronal
                    dim_x_index = 2;
                    dim_y_index = 3;
                    dim_z_index = 1;
                case TDImageOrientation.Sagittal
                    dim_x_index = 1;
                    dim_y_index = 3;
                    dim_z_index = 2;
                case TDImageOrientation.Axial
                    dim_x_index = 2;
                    dim_y_index = 1;
                    dim_z_index = 3;
            end
        end
        
        function Resize(obj)
            set(obj.m_parent, 'Units', 'Pixels');

            parent_position = get(obj.m_parent, 'Position');
            parent_width_pixels = parent_position(3);
            parent_height_pixels = parent_position(4);
            
            % Position the 3 main components : axes, slice slider and
            % control panel
            control_panel_height = 33;
            control_panel_width = parent_width_pixels;
            slice_slider_width = 16;
            slice_slider_height = max(1, parent_height_pixels - control_panel_height);
            axes_height = max(1, parent_height_pixels - control_panel_height);
            axes_width = max(1, parent_width_pixels - slice_slider_width);
            axes_position = control_panel_height;
            set(obj.m_axes, 'Units', 'Pixels', 'Position', [slice_slider_width axes_position axes_width axes_height]);
            set(obj.m_control_panel, 'Units', 'Pixels', 'Position', [1 1 control_panel_width control_panel_height]);
            set(obj.m_slice_slider, 'Units', 'Pixels', 'Position', [0 control_panel_height slice_slider_width slice_slider_height]);

            % Add the 4 subpanels to the control panel
            button_width = 32;
            orientation_width = 3*button_width;
            mouse_controls_width = 5*button_width;
            mouse_controls_position = parent_width_pixels - mouse_controls_width + 1;
            central_panels_width = max(1, (parent_width_pixels - mouse_controls_width - orientation_width)/2);
            windowlevel_panel_position = orientation_width + central_panels_width + 1;
            set(obj.m_orientation_panel, 'Units', 'Pixels', 'Position', [1 1 orientation_width control_panel_height]);
            set(obj.m_mouse_control_panel, 'Units', 'Pixels', 'Position', [mouse_controls_position 1 mouse_controls_width control_panel_height]);
            set(obj.m_imageoverlay_panel, 'Units', 'Pixels', 'Position', [orientation_width+1 1 central_panels_width control_panel_height]);
            set(obj.m_windowlevel_panel, 'Units', 'Pixels', 'Position', [windowlevel_panel_position 1 central_panels_width control_panel_height]);

            % Setup orientation panel
            set(obj.m_orientation_buttons(1), 'Units', 'Pixels', 'Position', [1 1 button_width  button_width]);
            set(obj.m_orientation_buttons(2), 'Units', 'Pixels', 'Position', [1+button_width 1 button_width button_width]);
            set(obj.m_orientation_buttons(3), 'Units', 'Pixels', 'Position', [1+button_width*2 1 button_width button_width]);

            % Setup mouse controls panel
            set(obj.m_mouse_control_buttons(1), 'Units', 'Pixels', 'Position', [1 1 button_width  button_width]);
            set(obj.m_mouse_control_buttons(2), 'Units', 'Pixels', 'Position', [1+button_width   1 button_width button_width]);
            set(obj.m_mouse_control_buttons(3), 'Units', 'Pixels', 'Position', [1+button_width*2 1 button_width button_width]);
            set(obj.m_mouse_control_buttons(4), 'Units', 'Pixels', 'Position', [1+button_width*3 1 button_width button_width]);
            set(obj.m_mouse_control_buttons(5), 'Units', 'Pixels', 'Position', [1+button_width*4 1 button_width button_width]);

            % Setup image/overlay panel
            halfpanel_height = 16;
            checkbox_width = 70;
            status_width = max(1, central_panels_width - checkbox_width);
            set(obj.m_image_checkbox, 'Units', 'Pixels', 'Position', [1 1+halfpanel_height checkbox_width halfpanel_height]);
            set(obj.m_status_text, 'Units', 'Pixels', 'Position', [1+checkbox_width halfpanel_height status_width halfpanel_height]);
            set(obj.m_overlay_checkbox, 'Units', 'Pixels', 'Position', [1 1 checkbox_width halfpanel_height]);
            set(obj.m_opacity_slider, 'Units', 'Pixels', 'Position', [checkbox_width 1 status_width halfpanel_height]);
            
            % Setup window/level panel
            windowlevel_text_width = 60;      
            windowlevel_editbox_width = 60;%40;
            windowlevel_editbox_height = 20; %18
            
            windowlevel_slider_width = max(1, central_panels_width - windowlevel_text_width - windowlevel_editbox_width);
            windowlevel_editbox_position =  1+windowlevel_text_width;
            windowlevel_slider_position = 1+windowlevel_text_width + windowlevel_editbox_width;
            set(obj.m_level_text, 'Units', 'Pixels', 'Position', [1 0 windowlevel_text_width halfpanel_height]);
            set(obj.m_level_editbox, 'Units', 'Pixels', 'Position', [windowlevel_editbox_position 0 windowlevel_editbox_width windowlevel_editbox_height]);
            set(obj.m_level_slider, 'Units', 'Pixels', 'Position', [windowlevel_slider_position 1 windowlevel_slider_width halfpanel_height]);
            set(obj.m_window_text, 'Units', 'Pixels', 'Position', [1 halfpanel_height windowlevel_text_width halfpanel_height]);
            set(obj.m_window_editbox, 'Units', 'Pixels', 'Position', [windowlevel_editbox_position halfpanel_height-1 windowlevel_editbox_width windowlevel_editbox_height]);
            set(obj.m_window_slider, 'Units', 'Pixels', 'Position', [windowlevel_slider_position 1+halfpanel_height windowlevel_slider_width halfpanel_height]);

            axis(obj.m_axes, 'fill');
        end
        
        function UpdateStatus(obj)
            main_image = obj.BackgroundImage;
            if isempty(main_image) || ~main_image.ImageExists
                status_text = 'No image';
            else
                rescale_text = '';
                [i, j, k] = obj.GetImageCoordinates;
                
                global_coords = obj.BackgroundImage.LocalToGlobalCoordinates([i, j, k]);
                
                i_text = int2str(global_coords(1));
                j_text = int2str(global_coords(2));
                k_text = int2str(global_coords(3));
                    
                if (main_image.IsPointInImage([i, j, k]))
                    voxel_value = main_image.GetValue([i, j, k]);
                    value_text = int2str(voxel_value);
                    
                    [rescale_value, rescale_units] = main_image.GetRescaledValue([i, j, k]);
                    if ~isempty(rescale_units) && ~isempty(rescale_value)
                        rescale_text = [rescale_units ':' int2str(rescale_value)];
                    end
                else
                    value_text = '-';
                    switch obj.Orientation
                        case TDImageOrientation.Coronal
                            j_text = '--';
                            k_text = '--';
                        case TDImageOrientation.Sagittal
                            i_text = '--';
                            k_text = '--';
                        case TDImageOrientation.Axial
                            i_text = '--';
                            j_text = '--';
                    end
                            
                end
            
                status_text = ['X:' j_text ' Y:' i_text ' Z:' k_text ' I:' value_text ' ' rescale_text];
            end
            set(obj.m_status_text, 'String', status_text);
        end

        function [i j k] = GetImageCoordinates(obj)
            coords = round(get(obj.m_axes, 'CurrentPoint'));
            if (~isempty(coords))
                i_screen = coords(2,1);
                j_screen = coords(2,2);
                k_screen = obj.SliceNumber(obj.Orientation);
                
                switch obj.Orientation
                    case TDImageOrientation.Coronal
                        i = k_screen;
                        j = i_screen;
                        k = j_screen;
                    case TDImageOrientation.Sagittal
                        i = i_screen;
                        j = k_screen;
                        k = j_screen;
                    case TDImageOrientation.Axial
                        i = j_screen;
                        j = i_screen;
                        k = k_screen;
                end
            else
                i = 1;
                j = 1;
                k = 1;
            end
        end

        function screen_coords = GetScreenCoordinates(obj)
            coords = get(obj.m_axes, 'CurrentPoint');
            if (~isempty(coords))
                i_screen = coords(2,1);
                j_screen = coords(2,2);
                screen_coords = [i_screen, j_screen];
            else
                screen_coords = [0, 0];
            end
        end

        function ClearAxesCache(obj)
            obj.m_previous_orientation = [];
            obj.m_axis_limits = [];
            obj.m_axis_limits{1} = {};
            obj.m_axis_limits{2} = {};
            obj.m_axis_limits{3} = {};            
        end
        
        % This function should be called when the image is
        % changed
        function ImageChanged(obj)
            obj.ClearAxesCache;
            obj.UpdateAxes;
            obj.UpdateGuiForNewImageOrOrientation;
            obj.UpdateGui;
            obj.DrawImages(true, false, false);
            obj.UpdateStatus;
            obj.MarkerPointManager.ImageChanged;
        end

        % This function should be called when the orientation is
        % changed
        function OrientationChanged(obj)
            obj.UpdateAxes;
            obj.UpdateGuiForNewImageOrOrientation;
            obj.UpdateGui;
            obj.DrawImages(true, true, true);
            obj.UpdateStatus;
            obj.MarkerPointManager.NewSliceOrOrientation;
        end
            

        function OverlayImageChanged(obj)
            obj.DrawImages(false, true, false);
        end
        
        function UpdateGuiForNewImageOrOrientation(obj)
            main_image = obj.BackgroundImage;
            if ~isempty(main_image) && main_image.ImageExists
                set(obj.m_opacity_slider, 'Min', 0);
                set(obj.m_opacity_slider, 'Max', 100);
                limits = main_image.Limits;

                set(obj.m_window_slider, 'Min', 0);
                set(obj.m_window_slider, 'Max', max(1, limits(2) - limits(1)));
                if obj.Window < 0
                    obj.Window = 0;
                end
                if obj.Window > max(1, limits(2) - limits(1))
                    obj.Window = max(1, limits(2) - limits(1));
                end
                
                set(obj.m_level_slider, 'Min', limits(1));
                set(obj.m_level_slider, 'Max', max(limits(1)+1, limits(2)));
                if obj.Level < limits(1)
                    obj.Level = limits(1);
                end
                if obj.Level > limits(2)
                    obj.Level = limits(2);
                end
                
                image_size = main_image.ImageSize;
                slider_max =  max(2, image_size(obj.Orientation));
                slider_min = 1;
                if obj.SliceNumber(obj.Orientation) > image_size(obj.Orientation)
                    obj.SliceNumber(obj.Orientation) = image_size(obj.Orientation);
                end
                if obj.SliceNumber(obj.Orientation) < 1
                    obj.SliceNumber(obj.Orientation) = 1;
                end
                
                set(obj.m_slice_slider, 'Min', slider_min);

                current_slice_value = get(obj.m_slice_slider, 'Value');
                if (current_slice_value ~= obj.SliceNumber(obj.Orientation))
                    set(obj.m_slice_slider, 'Value', obj.SliceNumber(obj.Orientation));                    
                end
                
                set(obj.m_slice_slider, 'Max', slider_max);
                set(obj.m_slice_slider, 'SliderStep', [1/(slider_max - slider_min), 10/(slider_max-slider_min)]);
            end
        end
                
        function UpdateGui(obj)
            main_image = obj.BackgroundImage;
            if ~isempty(main_image) && main_image.ImageExists
                set(obj.m_orientation_buttons(obj.Orientation), 'Value', 1);
                set(obj.m_mouse_control_buttons(obj.SelectedControl), 'Value', 1);
                set(obj.m_overlay_checkbox, 'Value', obj.ShowOverlay);
                set(obj.m_image_checkbox, 'Value', obj.ShowImage);
                set(obj.m_window_editbox, 'String', num2str(obj.Window));
                set(obj.m_window_slider, 'Value', obj.Window);
                set(obj.m_level_editbox, 'String', num2str(obj.Level));
                set(obj.m_level_slider, 'Value', obj.Level);
                set(obj.m_opacity_slider, 'Value', obj.OverlayOpacity);
                
                image_size = main_image.ImageSize;
                if obj.SliceNumber(obj.Orientation) > image_size(obj.Orientation)
                    obj.SliceNumber(obj.Orientation) = image_size(obj.Orientation);
                end
                if obj.SliceNumber(obj.Orientation) < 1
                    obj.SliceNumber(obj.Orientation) = 1;
                end
                current_slice_value = get(obj.m_slice_slider, 'Value');
                if (current_slice_value ~= obj.SliceNumber(obj.Orientation))
                    set(obj.m_slice_slider, 'Value', obj.SliceNumber(obj.Orientation));                    
                end

            end
        end
                
        function image_slice = GetImageSlice(obj, image_object)
            image_slice = image_object.GetSlice(obj.SliceNumber(obj.Orientation), obj.Orientation);
            if (obj.Orientation ~= TDImageOrientation.Axial)
                image_slice = image_slice';
            end
        end

        function DrawImages(obj, update_background, update_overlay, update_quiver)
            if update_background
                obj.DrawImage(1, 100*obj.ShowImage, obj.BackgroundImage);
            end
            if update_overlay
                obj.DrawImage(2, obj.OverlayOpacity*obj.ShowOverlay, obj.OverlayImage);
            end
            if update_quiver
                obj.DrawQuiverPlot(obj.ShowOverlay);
            end
        end
        
        function DrawQuiverPlot(obj, quiver_on)
            image_number = 3;
            quiver_image_object = obj.QuiverImage;
            if ~isempty(quiver_image_object) && quiver_image_object.ImageExists
                if quiver_image_object.ImageExists
                    qs = obj.GetQuiverSlice(quiver_image_object, obj.SliceNumber(obj.Orientation));
                    
                    image_size = quiver_image_object.ImageSize;
                    
                    switch obj.Orientation
                        case TDImageOrientation.Coronal
                            xy = [2 3];
                        case TDImageOrientation.Sagittal
                            xy = [1 3];
                        case TDImageOrientation.Axial
                            xy = [2 1];
                    end
                    x_range = 1 : image_size(xy(1));
                    y_range = 1 : image_size(xy(2));
                    
                    % Create an image handle if one doesn't already exist
                    if isempty(obj.image_handles{image_number})
                        obj.image_handles{3} = quiver([], [], [], [], 'Parent', obj.m_axes, 'Color', 'red');
                    end
                     
                    set(obj.image_handles{image_number}, 'XData', x_range);
                    set(obj.image_handles{image_number}, 'YData', y_range);
                    if quiver_on
                        set(obj.image_handles{image_number}, 'UData', qs(:, :, xy(1)));
                        set(obj.image_handles{image_number}, 'VData', qs(:, :, xy(2)));
                        set(obj.image_handles{image_number}, 'Visible', 'on')
                    else
                       set(obj.image_handles{image_number}, 'UData', []);
                       set(obj.image_handles{image_number}, 'VData', []);
                       set(obj.image_handles{image_number}, 'Visible', 'off')
                    end

                else
                    set(obj.image_handles{image_number}, 'UData', []);
                    set(obj.image_handles{image_number}, 'VData', []);
                    set(obj.image_handles{image_number}, 'Visible', 'off')
                end
            end            
        end

        function slice = GetQuiverSlice(obj, image_object, slice_number)
            switch obj.Orientation
                case TDImageOrientation.Coronal
                    slice = squeeze(image_object.RawImage(slice_number, :, :, :));
                case TDImageOrientation.Sagittal
                    slice = squeeze(image_object.RawImage(:, slice_number, :, :));
                case TDImageOrientation.Axial
                    slice = squeeze(image_object.RawImage(:, :, slice_number, :));
                otherwise
                    error('Unsupported dimension');
            end
            if (obj.Orientation ~= TDImageOrientation.Axial)
                slice = permute(slice, [2 1 3]);
            end
        end
        
        
        function DrawImage(obj, image_number, opacity, image_object)
            if ~isempty(image_object)
                if image_object.ImageExists
                    image_slice = obj.GetImageSlice(image_object);
                    image_type = image_object.ImageType;
                    
                    if (image_type == TDImageType.Scaled) || (image_type == TDImageType.Colormap)
                        limits = image_object.Limits;
                    else
                        limits = [];
                    end
                    [rgb_slice, alpha_slice] = obj.GetImage(image_slice, limits, image_type, obj.Window, obj.Level, obj.BlackIsTransparent);
                    alpha_slice = double(alpha_slice)*opacity/100;
                    
                    if isempty(obj.image_handles{image_number})
                        obj.image_handles{image_number} = imshow([], 'Parent', obj.m_axes);
                    end
                    
                    set(obj.image_handles{image_number}, 'CData', rgb_slice);
                    set(obj.image_handles{image_number}, 'AlphaData', alpha_slice);
                    set(obj.image_handles{image_number},'AlphaDataMapping','none');
                else
                    set(obj.image_handles{image_number}, 'CData', []);                    
                end
            end

        end
            
        
        
        
        
        %%%%%%%%%%%%%
        % Callbacks %
        %%%%%%%%%%%%%
        
        
        % Scroll wheel used to cine through slices
        function WindowScrollWheelFcn(obj, ~, eventdata)
            scroll_count = eventdata.VerticalScrollCount; % positive = scroll down            
            obj.SliceNumber(obj.Orientation) = obj.SliceNumber(obj.Orientation) + scroll_count;
        end
                
        % Show overlay checkbox
        function OverlayCheckboxCallback(obj, hObject, ~, ~)
            obj.ShowOverlay = get(hObject, 'Value');
        end
        
        % Show image checkbox
        function ImageCheckboxCallback(obj, hObject, ~, ~)
            obj.ShowImage = get(hObject, 'Value');
        end
        
        % Window slider
        function WindowSliderCallback(obj, hObject, ~, ~)
            obj.Window = round(get(hObject,'Value'));
        end

        % Level slider
        function LevelSliderCallback(obj, hObject, ~, ~)
            obj.Level = round(get(hObject,'Value'));
        end

        % Window edit box
        function WindowTextCallback(obj, hObject, ~, ~)
            obj.Window = round(str2double(get(hObject,'String')));
        end
        
        % Level edit box
        function LevelTextCallback(obj, hObject, ~, ~)
            obj.Level = round(str2double(get(hObject,'String')));
        end

        % Settings have changed
        function SettingsChangedCallback(obj, ~, ~, ~)
            obj.UpdateGui;
            obj.DrawImages(true, true, true);
            obj.UpdateStatus;
        end
        
        % Slice number has changed
        function SliceNumberChangedCallback(obj, ~, ~, ~)
            obj.UpdateGui;
            obj.MarkerPointManager.NewSliceOrOrientation;
            obj.DrawImages(true, true, true);
            obj.UpdateStatus;
        end

        % Image pointerhas changed
        function ImagePointerChangedCallback(obj, ~, ~)
            obj.ImagePointerChanged;
        end
        
        % Image has changed
        function ImageChangedCallback(obj, ~, ~)
            obj.ImageChanged;
        end

        % Orientation has changed
        function OrientationChangedCallback(obj, ~, ~)
            obj.OrientationChanged;
        end
        
        % Overlay image has changed
        function OverlayImageChangedCallback(obj, ~, ~)
            obj.OverlayImageChanged;
        end

        % Overlay image has changed
        function OverlayImagePointerChangedCallback(obj, ~, ~)
            obj.OverlayImagePointerChanged;
        end
        
        % Quiver image has changed
        function QuiverImagePointerChangedCallback(obj, ~, ~)
            obj.QuiverImagePointerChanged;
        end
        
        % Overlay image has changed
        function MarkerImageChangedCallback(obj, ~, ~)
            obj.MarkerImageChanged;
        end
        
        function MousePan(obj)
            screen_coords = obj.GetScreenCoordinates;

            pan_offset = screen_coords - obj.m_last_coordinates;
            x_lim = get(obj.m_axes, 'XLim');
            x_lim = x_lim - pan_offset(1);
            y_lim = get(obj.m_axes, 'YLim');
            y_lim = y_lim - pan_offset(2);
            set(obj.m_axes, 'XLim', x_lim)
            set(obj.m_axes, 'YLim', y_lim)
        end

        function MouseZoom(obj)
            screen_coords = obj.GetScreenCoordinates;

            coords_offset = screen_coords - obj.m_last_coordinates;
            
            x_lim = get(obj.m_axes, 'XLim');
            x_range = x_lim(2) - x_lim(1);
            
            y_lim = get(obj.m_axes, 'YLim');
            y_range = y_lim(2) - y_lim(1);
            y_relative_movement = coords_offset(2)/y_range;

            relative_scale = y_relative_movement;
            x_range_scale = relative_scale*x_range/1;
            y_range_scale = relative_scale*y_range/1;
            
            x_lim = [x_lim(1) - x_range_scale, x_lim(2) + x_range_scale];
            
            y_lim = [y_lim(1) - y_range_scale, y_lim(2) + y_range_scale];
            
            if (abs(x_lim(2) - x_lim(1)) > 10) && (abs(y_lim(2) - y_lim(1)) > 10) && ...
                    (abs(x_lim(2) - x_lim(1)) < 1000) && (abs(y_lim(2) - y_lim(1)) < 500)
                set(obj.m_axes, 'XLim', x_lim)
                set(obj.m_axes, 'YLim', y_lim)
            end
            
            obj.m_last_coordinates = screen_coords;
        end

        % Change window and level via tool
        function MouseWL(obj)
            screen_coords = obj.GetScreenCoordinates;

            coords_offset = screen_coords - obj.m_last_coordinates;
            
            x_lim = get(obj.m_axes, 'XLim');
            x_range = x_lim(2) - x_lim(1);
            x_relative_movement = coords_offset(1)/x_range;
            
            y_lim = get(obj.m_axes, 'YLim');
            y_range = y_lim(2) - y_lim(1);
            y_relative_movement = coords_offset(2)/y_range;

            new_window = obj.Window + x_relative_movement*100*30;
            new_window = max(new_window, get(obj.m_window_slider, 'Min'));
            new_window = min(new_window, get(obj.m_window_slider, 'Max'));
            obj.Window = new_window;
            
            new_level = obj.Level + y_relative_movement*100*30;
            new_level = max(new_level, get(obj.m_level_slider, 'Min'));
            new_level = min(new_level, get(obj.m_level_slider, 'Max'));
            obj.Level = new_level;
            obj.m_last_coordinates = screen_coords;
        end

        % Change window and level via tool
        function MouseCine(obj)
            screen_coords = obj.GetScreenCoordinates;

            coords_offset = screen_coords - obj.m_last_coordinates;
            
            y_lim = get(obj.m_axes, 'YLim');
            y_range = y_lim(2) - y_lim(1);
            y_relative_movement = coords_offset(2)/y_range;
            direction = sign(y_relative_movement);
            y_relative_movement = abs(y_relative_movement);
            y_relative_movement = 100*y_relative_movement;
            y_relative_movement = ceil(y_relative_movement);

            k_position = obj.SliceNumber(obj.Orientation);
            k_position = k_position - direction*y_relative_movement;
            obj.SliceNumber(obj.Orientation) = k_position;
            obj.m_last_coordinates = screen_coords;
        end
        
        % Mouse has moved over the figure
        function MouseHasMoved(obj, hObject, eventData)
            if obj.m_mouse_down
                selection_type = get(hObject, 'SelectionType');
                
                if strcmp(selection_type, 'extend')
                    obj.MousePan;
                elseif strcmp(selection_type, 'alt')
                    obj.MouseZoom;
                elseif obj.SelectedControl == 3
                elseif obj.SelectedControl == 4
                    obj.MouseWL;
                elseif obj.SelectedControl == 5
                    obj.MouseCine;
                end
            end
            
            if obj.SelectedControl == 3
                obj.MarkerPointManager.MouseMoved(obj.GetScreenCoordinates);
            end
            
            obj.UpdateCursor(hObject);          
            obj.UpdateStatus();
            if (~isempty(obj.m_WindowButtonMotionFcn))
                obj.m_WindowButtonMotionFcn(hObject, eventData);
            end
        end
        
        function UpdateCursor(obj, hObject)
            [i, j, k] = obj.GetImageCoordinates;            
            point_is_in_image = obj.BackgroundImage.IsPointInImage([i, j, k]);
            if (~point_is_in_image)
                obj.m_mouse_down = false;                
            end
            
            if (obj.SelectedControl == 3) && (point_is_in_image)
                % Make cursor a cross, if it isn't already
                if ~obj.CursorIsACross
                    set(hObject, 'Pointer', 'cross');
                    obj.CursorIsACross = true;
                end
            else
                % Make cursor a pointer, if it currently a cross
                if obj.CursorIsACross
                    set(hObject, 'Pointer', 'arrow');
                    obj.CursorIsACross = false;
                end
            end

        end

        % Mouse has been clicked
        function MouseDown(obj, src, ~)
            obj.m_last_coordinates = obj.GetScreenCoordinates;
            obj.m_mouse_down = true;
            selection_type = get(src, 'SelectionType');
            if strcmp(selection_type, 'normal')
                [i, j, k] = obj.GetImageCoordinates;
                coord = [i, j, k];
                if (obj.BackgroundImage.IsPointInImage(coord))
                    if (obj.SelectedControl == 3)
                        obj.MarkerPointManager.MouseDown(obj.GetScreenCoordinates);
                    else
                        notify(obj, 'MouseClickInImage', TDEventData(coord));
                    end
                end
            end
        end

        % Mouse has been clicked
        function MouseUp(obj, src, ~)
            obj.m_mouse_down = false;
            
            obj.m_last_coordinates = obj.GetScreenCoordinates;
            selection_type = get(src, 'SelectionType');
            if (obj.SelectedControl == 3) && strcmp(selection_type, 'normal')
                [i, j, k] = obj.GetImageCoordinates;
                if (obj.BackgroundImage.IsPointInImage([i, j, k]))
                    obj.MarkerPointManager.MouseUp(obj.GetScreenCoordinates);
                end
            end
        end
        
        % Key has been clicked
        function KeyPressed(obj, ~, eventdata)
            obj.ShortcutKeys(eventdata.Key);
        end
        
        function ShortcutKeys(obj, key)
            if strcmpi(key, 'c')
                obj.Orientation = TDImageOrientation.Coronal;
            elseif strcmpi(key, 's')
                obj.Orientation = TDImageOrientation.Sagittal;
            elseif strcmpi(key, 'a')
                obj.Orientation = TDImageOrientation.Axial;
            elseif strcmpi(key, 'z')
                obj.SetControl('Zoom');
            elseif strcmpi(key, 'p')
                obj.SetControl('Pan');
            elseif strcmpi(key, 'm')
                obj.SetControl('Mark');
            elseif strcmpi(key, 'w')
                obj.SetControl('W/L');
            elseif strcmpi(key, 'e')
                obj.SetControl('Cine');
            elseif strcmpi(key, 'i')
                obj.ShowImage = ~obj.ShowImage;
            elseif strcmpi(key, 't')
                obj.BlackIsTransparent = ~obj.BlackIsTransparent;
            elseif strcmpi(key, 'o')
                obj.ShowOverlay = ~obj.ShowOverlay;
            elseif strcmpi(key, 'l') % L
                obj.MarkerPointManager.ChangeShowTextLabels(~obj.MarkerPointManager.ShowTextLabels);
            elseif strcmpi(key, '1') % one
                obj.MarkerPointManager.ChangeCurrentColour(1);
            elseif strcmpi(key, '2')
                obj.MarkerPointManager.ChangeCurrentColour(2);
            elseif strcmpi(key, '3')
                obj.MarkerPointManager.ChangeCurrentColour(3);
            elseif strcmpi(key, '4')
                obj.MarkerPointManager.ChangeCurrentColour(4);
            elseif strcmpi(key, '5')
                obj.MarkerPointManager.ChangeCurrentColour(5);
            elseif strcmpi(key, '6')
                obj.MarkerPointManager.ChangeCurrentColour(6);
            elseif strcmpi(key, '7')
                obj.MarkerPointManager.ChangeCurrentColour(7);
            elseif strcmpi(key, 'space')
                obj.MarkerPointManager.GotoNearestMarker;
            elseif strcmpi(key, 'backspace')
                obj.MarkerPointManager.DeleteHighlightedMarker;
            elseif strcmpi(key, 'leftarrow')
                obj.MarkerPointManager.GotoPreviousMarker;
            elseif strcmpi(key, 'rightarrow')
                obj.MarkerPointManager.GotoNextMarker;
            elseif strcmpi(key, 'pageup')
                obj.MarkerPointManager.GotoFirstMarker;
            elseif strcmpi(key, 'pagedown')
                obj.MarkerPointManager.GotoLastMarker;
            elseif strcmpi(key, 'downarrow')
                obj.SliceNumber(obj.Orientation) = obj.SliceNumber(obj.Orientation) + 1;
            elseif strcmpi(key, 'uparrow')
                obj.SliceNumber(obj.Orientation) = obj.SliceNumber(obj.Orientation) - 1;
            end            
        end
        
        function OrientationCallback(obj, ~, eventdata, ~)
            switch get(eventdata.NewValue, 'Tag')
                case 'Coronal'
                    obj.Orientation = TDImageOrientation.Coronal;
                case 'Sagittal'
                    obj.Orientation = TDImageOrientation.Sagittal;
                case 'Axial'
                    obj.Orientation = TDImageOrientation.Axial;
            end
        end
        
        
        
        function SliderCallback(obj, hObject, ~)
            obj.SliceNumber(obj.Orientation) = round(get(hObject,'Value'));
        end

        function OpacitySliderCallback(obj, hObject, ~, ~)
            obj.OverlayOpacity = get(hObject,'Value');
        end
        
        function CustomResize(obj, eventdata, handles)
            obj.Resize;
            if (~isempty(obj.m_resize_fcn))
                obj.m_resize_fcn(eventdata, handles);
            end
        end
        
        function SetControl(obj, tag_value)
            switch tag_value
                case 'Zoom'
                    obj.SelectedControl = 1;
                    obj.UpdateCursor(obj.FigureHandle);
                    pan(obj.m_axes, 'off'); zoom(obj.m_axes, 'on');
                    obj.RestoreKeyPressCallback;
                case 'Pan'
                    obj.SelectedControl = 2;
                    obj.UpdateCursor(obj.FigureHandle);
                    pan(obj.m_axes, 'on'); zoom(obj.m_axes, 'off');
                    obj.RestoreKeyPressCallback;
                case 'Mark'
                    obj.SelectedControl = 3;
                    pan(obj.m_axes, 'off'); zoom(obj.m_axes, 'off');
                    obj.UpdateCursor(obj.FigureHandle);
                    obj.notify('MarkerPanelSelected');
                case 'W/L'
                    obj.SelectedControl = 4;
                    pan(obj.m_axes, 'off'); zoom(obj.m_axes, 'off');
                    obj.UpdateCursor(obj.FigureHandle);
                case 'Cine'
                    obj.SelectedControl = 5;
                    pan(obj.m_axes, 'off'); zoom(obj.m_axes, 'off');
                    obj.UpdateCursor(obj.FigureHandle);
            end
            obj.MarkerPointManager.Enable(obj.SelectedControl == 3);
            set(obj.m_mouse_control_buttons(obj.SelectedControl), 'Value', 1);
        end

        function ControlsCallback(obj, ~, eventdata, ~)
            obj.SetControl(get(eventdata.NewValue, 'Tag'));
        end
        
    end
    methods (Access = private, Static)
        
        function [rgb_slice alpha_slice] = GetImage(image_slice, limits, image_type, window, level, black_is_transparent)
            switch image_type
                case TDImageType.Grayscale
                    rescaled_image_slice = TDViewerPanel.RescaleImage(image_slice, window, level);
                    [rgb_slice, alpha_slice] = TDViewerPanel.GetBWImage(rescaled_image_slice);
                case TDImageType.Colormap
                    if limits(1) < 0
                        image_slice = image_slice - limits(1);
                    end
                    [rgb_slice, alpha_slice] = TDViewerPanel.GetLabeledImage(image_slice);
                case TDImageType.Scaled
                    [rgb_slice, alpha_slice] = TDViewerPanel.GetColourMap(image_slice, limits, black_is_transparent);
            end
            
        end
        
        function [rgb_image alpha] = GetBWImage(image)
            rgb_image = (cat(3, image, image, image));
            alpha = ones(size(image));
        end

        function [rgb_image alpha] = GetLabeledImage(image)
            data_class = class(image);
            if strcmp(data_class, 'double') || strcmp(data_class, 'single')
                rgb_image = label2rgb(round(image), 'lines');
            else
                rgb_image = label2rgb(image, 'lines');
            end
            alpha = int8(image ~= 0);
        end

        function [rgb_image alpha] = GetColourMap(image, image_limits, black_is_transparent)
            image_limits(1) = min(0, image_limits(1));
            image_limits(2) = max(0, image_limits(2));
            positive_mask = image >= 0;
            rgb_image = zeros([size(image), 3], 'uint8');
            positive_image = abs(double(image))/abs(double(image_limits(2)));
            negative_image = abs(double(image))/abs(double(image_limits(1)));
            rgb_image(:, :, 1) = uint8(positive_mask).*(uint8(255*positive_image));
            rgb_image(:, :, 3) = uint8(~positive_mask).*(uint8(255*negative_image));
            
            if black_is_transparent
                alpha = int8(min(1, abs(max(positive_image, negative_image))));
            else
                alpha = ones(size(image));
            end
        end
        
        function rescaled_image = RescaleImage(image, window, level)
            min_value = level - window/2;
            max_value = level + window/2;
            scale_factor = 255/max(1, (max_value - min_value));
            rescaled_image = uint8(min(((image - min_value)*scale_factor), 255));
        end          
    end
end

