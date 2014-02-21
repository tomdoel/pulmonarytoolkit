classdef PTKViewerPanel < handle
    % PTKViewerPanel. Creates a data viewer window for imaging 3D data slice-by-slice.
    %
    %     PTKViewerPanel creates a visualisation window on the supplied
    %     graphics handle. It creates the viewer panel, scrollbar, orientation
    %     and tool controls, a status window and controls for toggling the image
    %     and overlay on and off and changing overlay transparency.
    %
    %     PTKViewerPanel is used as a component by the standalong data viewer
    %     application PTKViewer, and by the Pulmonary Toolkit gui application.
    %     You can also use this in your own user interfaces.
    %
    %     New background, overlay and quiver plots can be viewed by assigning
    %     images (within a PTKViewer class) to the BackgroundImage, OverlayImage
    %     and QuiverImage properties.
    %
    %     To set the marker image, use MarkerPointManager.ChangeMarkerImage
    %
    %     See PTKViewer.m for a simple example of how to use this class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    
    properties (SetObservable)
        Orientation = PTKImageOrientation.Coronal
        OverlayOpacity = 50
        ShowImage = true
        ShowOverlay = true
        BlackIsTransparent = true
        Window = 1600
        Level = -600
        SliceNumber = [1 1 1]
        SliceSkip = 10
        BackgroundImage
        OverlayImage
        QuiverImage
        OpaqueColour % If set, then this colour will always be shown at full opacity in the overlay
    end
    
    properties
        MarkerPointManager
    end
    
    events
        MarkerPanelSelected
    end
    
    
    properties (Access = private)
        Tools
        CineTool
        WindowLevelTool
        ZoomTool
        PanTool
        PanMatlabTool
        ZoomMatlabTool
        EditTool
        ReplaceColourTool
        MapColourTool
    end

    properties (Access = private)
        FigureHandle
        CandidatePoints
        CursorIsACross = false
        CurrentCursor = ''
        Parent
        ImageHandles = {[], [], []} % Handles to image and overlay
        SelectedControl = 'W/L'
        
        % Gui elements
        ControlPanel;
        ImageOverlayPanel;
        WindowLevelPanel;
        Axes;
        SliceSlider;
        OrientationPanel;
        OrientationButtons;
        OpacitySlider;
        ImageCheckbox;
        OverlayCheckbox;
        StatusText;
        WindowText;
        WindowEditbox;
        WindowSlider;
        LevelText;
        LevelEditbox;
        LevelSlider;
        MouseControlPanel;
        MouseControlButtons;
        
        AxisLimits;
        PreviousOrientation;

        % Callbacks
        ResizeFunction;
        WindowButtonMotionFcn;
        
        % Handles to listeners for image changes
        ImageChangedListeners = {[], [], []}
        
        % Used for programmatic pan, zoom, etc.
        LastCoordinates = [0, 0, 0]
        MouseIsDown = false
        
        ToolOnMouseDown
        
        LastCursor
    end

    events
        MouseClickInImage
    end
    
    methods
        function obj = PTKViewerPanel(parent)
            font_size = 9;
            obj.AxisLimits = [];
            obj.AxisLimits{1} = {};
            obj.AxisLimits{2} = {};
            obj.AxisLimits{3} = {};
            
            % These must be created here, not on the properties section, to
            % prevent Matlab creating a circular dependency (see Matlab solution 1-6K9BQ7)
            obj.BackgroundImage = PTKImage;
            obj.OverlayImage = PTKImage;
            obj.QuiverImage = PTKImage;

            
            obj.Parent = parent;
            
            obj.SliceSlider = uicontrol('Style', 'slider', 'Parent', obj.Parent, 'TooltipString', 'Scroll through slices');
            obj.Axes = axes('Parent', obj.Parent);
            
            obj.MarkerPointManager = PTKMarkerPointManager(obj, obj.Axes);
            obj.CineTool = PTKCineTool;
            obj.WindowLevelTool = PTKWindowLevelTool;
            obj.ZoomTool = PTKZoomTool;
            obj.PanTool = PTKPanTool;
            obj.PanMatlabTool = PTKPanMatlabTool(obj);
            obj.ZoomMatlabTool = PTKZoomMatlabTool(obj);
            obj.EditTool = PTKEditManager(obj);
            obj.ReplaceColourTool = PTKReplaceColourTool(obj, obj.Axes);
            obj.MapColourTool = PTKMapColourTool(obj, obj.Axes);
           
            tool_list = {obj.ZoomMatlabTool, obj.PanMatlabTool, obj.MarkerPointManager, obj.WindowLevelTool, obj.CineTool, obj.EditTool, obj.ReplaceColourTool, obj.MapColourTool};
            
            obj.ControlPanel = uipanel('Parent', obj.Parent, 'BorderType', 'none', 'BackgroundColor', 'black', 'ForegroundColor', 'white');

            obj.OrientationPanel = uibuttongroup('Parent', obj.ControlPanel, 'BorderType', 'none', 'SelectionChangeFcn', @obj.OrientationCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            obj.MouseControlPanel = uibuttongroup('Parent', obj.ControlPanel, 'BorderType', 'none', 'SelectionChangeFcn', @obj.ControlsCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            
            orientation_buttons = [0 0 0];
            orientation_buttons(1) = uicontrol('Style', 'togglebutton', 'Parent', obj.OrientationPanel, 'String', 'Cor', 'Units', 'pixels', 'FontSize', font_size, 'Tag', 'Coronal', 'TooltipString', 'View coronal slices (Y-Z)');
            orientation_buttons(2) = uicontrol('Style', 'togglebutton', 'Parent', obj.OrientationPanel, 'String', 'Sag', 'Units', 'pixels', 'FontSize', font_size, 'Tag', 'Sagittal', 'TooltipString', 'View sagittal slices (X-Z)');
            orientation_buttons(3) = uicontrol('Style', 'togglebutton', 'Parent', obj.OrientationPanel, 'String', 'Ax', 'Units', 'pixels', 'FontSize', font_size, 'Tag', 'Axial', 'TooltipString', 'View transverse slices (X-Y)');
            obj.OrientationButtons = orientation_buttons;
            
            % Buttons for each tool
            obj.MouseControlButtons = containers.Map;
            obj.Tools = containers.Map;
            
            for tool_set = tool_list
                tool = tool_set{1};
                tag = tool.Tag;
                obj.Tools(tag) = tool;
                obj.MouseControlButtons(tag) = uicontrol('Style', 'togglebutton', 'Parent', obj.MouseControlPanel, 'String', tool.ButtonText, 'Units', 'pixels', 'FontSize', font_size, 'Tag', tool.Tag, 'TooltipString', tool.ToolTip);
            end

            obj.WindowLevelPanel = uipanel('Parent', obj.ControlPanel, 'BorderType', 'none', 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            obj.ImageOverlayPanel = uipanel('Parent', obj.ControlPanel, 'BorderType', 'none', 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            
            obj.StatusText = uicontrol('Style', 'text', 'Parent', obj.ImageOverlayPanel, 'Units', 'pixels', 'FontSize', font_size, 'BackgroundColor', 'black', 'ForegroundColor', 'white');
            
            obj.OpacitySlider = uicontrol('Style', 'slider', 'Parent', obj.ImageOverlayPanel, 'Callback', @obj.OpacitySliderCallback, 'TooltipString', 'Change opacity of overlay');
            obj.ImageCheckbox = uicontrol('Style', 'checkbox', 'Parent', obj.ImageOverlayPanel, 'Units', 'pixels', 'FontSize', font_size, 'Callback', @obj.ImageCheckboxCallback, 'String', 'Image', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Show image');
            obj.OverlayCheckbox = uicontrol('Style', 'checkbox', 'Parent', obj.ImageOverlayPanel, 'Units', 'pixels', 'FontSize', font_size, 'Callback', @obj.OverlayCheckboxCallback, 'String', 'Overlay', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Show overlay over image');
          
            obj.WindowText = uicontrol('Style', 'text', 'Parent', obj.WindowLevelPanel, 'Units', 'pixels', 'FontSize', font_size, 'String', 'Window:', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'HorizontalAlignment', 'right');
            obj.LevelText = uicontrol('Style', 'text', 'Parent', obj.WindowLevelPanel, 'Units', 'pixels', 'FontSize', font_size, 'String', 'Level:', 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'HorizontalAlignment', 'right');
            obj.WindowEditbox = uicontrol('Style', 'edit', 'Parent', obj.WindowLevelPanel, 'Units', 'pixels', 'FontSize', font_size, 'Callback', @obj.WindowTextCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Change window (contrast)');
            obj.LevelEditbox = uicontrol('Style', 'edit', 'Parent', obj.WindowLevelPanel, 'Units', 'pixels', 'FontSize', font_size, 'Callback', @obj.LevelTextCallback, 'BackgroundColor', 'black', 'ForegroundColor', 'white', 'TooltipString', 'Change level (brightness)');
            obj.WindowSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 1, 'Value', 1, 'Parent', obj.WindowLevelPanel, 'Callback', @obj.WindowSliderCallback, 'TooltipString', 'Change window (contrast)');
            obj.LevelSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 1, 'Value', 0, 'Parent', obj.WindowLevelPanel, 'Callback', @obj.LevelSliderCallback, 'TooltipString', 'Change level (brightness)');
            
            obj.ResizeFunction = get(parent, 'ResizeFcn');
            
            figure_handle = ancestor(parent, 'figure');
            obj.FigureHandle = figure_handle;
            obj.WindowButtonMotionFcn = get(figure_handle, 'WindowButtonMotionFcn');
            
            obj.UpdateGui;
            obj.UpdateStatus;
            obj.Resize;
            
            hold(obj.Axes, 'on');

            set(parent, 'ResizeFcn', @obj.CustomResize);
            set(figure_handle, 'WindowButtonMotionFcn', @obj.MouseHasMoved);
            set(figure_handle, 'WindowButtonUpFcn', @obj.MouseUp);
            set(figure_handle, 'WindowButtonDownFcn', @obj.MouseDown);
            set(figure_handle, 'WindowScrollWheelFcn', @obj.WindowScrollWheelFcn);
            set(figure_handle, 'KeyPressFcn', @obj.KeyPressed);
            

            obj.CaptureKeyboardInput(figure_handle);
            
            
            % Add custom listeners to allow continuous callbacks from the
            % sliders
            setappdata(parent ,'sliderListeners', handle.listener(obj.SliceSlider, 'ActionEvent', @obj.SliderCallback));
            setappdata(obj.ImageOverlayPanel, 'sliderListenersO', handle.listener(obj.OpacitySlider, 'ActionEvent', @obj.OpacitySliderCallback));
            setappdata(obj.WindowLevelPanel, 'sliderListenersW', handle.listener(obj.WindowSlider, 'ActionEvent', @obj.WindowSliderCallback));
            setappdata(obj.WindowLevelPanel, 'sliderListenersL', handle.listener(obj.LevelSlider, 'ActionEvent', @obj.LevelSliderCallback));
            
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
            addlistener(obj, 'OpaqueColour', 'PostSet', @obj.SettingsChangedCallback);
            
                                    
            % Listen for image change events
            addlistener(obj, 'BackgroundImage', 'PostSet', @obj.ImagePointerChangedCallback);
            obj.SetImage(obj.BackgroundImage);
            addlistener(obj, 'OverlayImage', 'PostSet', @obj.OverlayImagePointerChangedCallback);
            obj.SetOverlayImage(obj.OverlayImage);
            addlistener(obj, 'QuiverImage', 'PostSet', @obj.QuiverImagePointerChangedCallback);
            obj.SetQuiverImage(obj.QuiverImage);
            
            obj.UpdateTools;
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
            in_marker_mode = strcmp(obj.SelectedControl, 'Mark');
        end

        function in_edit_mode = IsInEditMode(obj)
            in_edit_mode = strcmp(obj.SelectedControl, 'Edit');
        end
        
        function delete(obj)
            obj.DeleteImageChangedListeners;
        end
        
        % Changes the current axis limits to the specified global coordinates
        % i_limits = [minimum_i, maximum_i] and the same for j, k.
        function ZoomTo(obj, i_limits, j_limits, k_limits)
            
            % Convert global coordinates to local coordinates
            i_limits_local = i_limits - obj.BackgroundImage.Origin(1) + 1;
            j_limits_local = j_limits - obj.BackgroundImage.Origin(2) + 1;
            k_limits_local = k_limits - obj.BackgroundImage.Origin(3) + 1;
            
            % Update the cached axis limits
            obj.AxisLimits{PTKImageOrientation.Coronal}.XLim = j_limits_local;
            obj.AxisLimits{PTKImageOrientation.Coronal}.YLim = k_limits_local;
            obj.AxisLimits{PTKImageOrientation.Sagittal}.XLim = i_limits_local;
            obj.AxisLimits{PTKImageOrientation.Sagittal}.YLim = k_limits_local;
            obj.AxisLimits{PTKImageOrientation.Axial}.XLim = j_limits_local;
            obj.AxisLimits{PTKImageOrientation.Axial}.YLim = i_limits_local;

            % Update the current axis limits
            switch obj.Orientation
                case PTKImageOrientation.Coronal
                    set(obj.Axes, 'XLim', j_limits_local)
                    set(obj.Axes, 'YLim', k_limits_local)
                case PTKImageOrientation.Sagittal
                    set(obj.Axes, 'XLim', i_limits_local)
                    set(obj.Axes, 'YLim', k_limits_local)
                case PTKImageOrientation.Axial
                    set(obj.Axes, 'XLim', j_limits_local)
                    set(obj.Axes, 'YLim', i_limits_local)
            end
            
            % Update the currently displayed slice to be the centre of the
            % requested box
            obj.SliceNumber = [round((i_limits_local(2)+i_limits_local(1))/2), round((j_limits_local(2)+j_limits_local(1))/2), round((k_limits_local(2)+k_limits_local(1))/2)];
        end
        
        function frame = Capture(obj)
            drawnow;
            
            % Matlab cannot capture images on a secondary monitor, so we must
            % move the figure to the primary monitor
            old_position = get(obj.Axes, 'Position');
            movegui(obj.Axes);
            
            % Fetch the current screen coordinates of the axes
            rect_screenpixels = get(obj.Axes, 'Position');
            
            % The image may not occupy the entire axes, so we need to crop the
            % rectangle to only include the image
            xlim = get(obj.Axes, 'XLim');
            ylim = get(obj.Axes, 'YLim');

            x_size_screenpixels = rect_screenpixels(3);
            x_size_imagepixels = xlim(2) - xlim(1);
            scale_x = x_size_screenpixels/x_size_imagepixels;
            y_size_screenpixels = rect_screenpixels(4);
            y_size_imagepixels = ylim(2) - ylim(1);
            scale_y = y_size_screenpixels/y_size_imagepixels;
            
            origin = [0.5, 0.5, 0.5];
            image_limit = origin + obj.BackgroundImage.ImageSize;
            switch obj.Orientation
                case PTKImageOrientation.Coronal
                    xlim_image = [origin(2), image_limit(2)];
                    ylim_image = [origin(3), image_limit(3)];
                case PTKImageOrientation.Sagittal
                    xlim_image = [origin(1), image_limit(1)];
                    ylim_image = [origin(3), image_limit(3)];
                case PTKImageOrientation.Axial
                    xlim_image = [origin(2), image_limit(2)];
                    ylim_image = [origin(1), image_limit(1)];
            end
            
            x_offset_imagevoxels = max(0, xlim_image(1) - xlim(1));
            x_offset_screenvoxels = x_offset_imagevoxels*scale_x;
            
            x_endoffset_imagevoxels = max(0, xlim(2) - xlim_image(2));
            x_endoffset_screenvoxels = x_endoffset_imagevoxels*scale_x;

            y_offset_imagevoxels = max(0, ylim_image(1) - ylim(1));
            y_offset_screenvoxels = y_offset_imagevoxels*scale_y;
            
            y_endoffset_imagevoxels = max(0, ylim(2) - ylim_image(2));
            y_endoffset_screenvoxels = y_endoffset_imagevoxels*scale_y;

            % Crop the image rectangle so it only contains the image
            rect_screenpixels(1) = rect_screenpixels(1) + x_offset_screenvoxels;
            rect_screenpixels(2) = rect_screenpixels(2) + y_offset_screenvoxels;
            rect_screenpixels(3) = rect_screenpixels(3) - x_offset_screenvoxels - x_endoffset_screenvoxels;
            rect_screenpixels(4) = rect_screenpixels(4) - y_offset_screenvoxels - y_endoffset_screenvoxels;
            rect_screenpixels = round(rect_screenpixels);

            % Capture the image as a bitmap
            frame = PTKImageUtilities.CaptureFigure(obj.FigureHandle, rect_screenpixels);
            
            % Return the figure to its original position 
            set(obj.Axes, 'Position', old_position);            
        end

        function SetWindowWithinLimits(obj, window)
            window = max(window, get(obj.WindowSlider, 'Min'));
            window = min(window, get(obj.WindowSlider, 'Max'));
            obj.Window = window;            
        end

        function SetLevelWithinLimits(obj, level)
            level = max(level, get(obj.LevelSlider, 'Min'));
            level = min(level, get(obj.LevelSlider, 'Max'));
            obj.Level = level;
        end
        
        % Adjusts the image axes to make the image visible between the specified
        % coordinates
        function SetImageLimits(obj, min_coords, max_coords)
            x_lim = [min_coords(1), max_coords(1)];
            y_lim = [min_coords(2), max_coords(2)];
            if x_lim(2) > x_lim(1)
                set(obj.Axes, 'XLim', x_lim);
            end
            if y_lim(2) > y_lim(1)
                set(obj.Axes, 'YLim', y_lim);
            end
        end
        
        % Gets the current limits of the visible image axes
        function [min_coords, max_coords] = GetImageLimits(obj)
            x_lim = get(obj.Axes, 'XLim');
            y_lim = get(obj.Axes, 'YLim');
            min_coords = [x_lim(1), y_lim(1)];
            max_coords = [x_lim(2), y_lim(2)];
        end
        
        function EnablePan(obj, enabled)
            if enabled
                pan(obj.Axes, 'on');
            else
                pan(obj.Axes, 'off');
            end
        end
        
        function EnableZoom(obj, enabled)
            if enabled
                zoom(obj.Axes, 'on');
            else
                zoom(obj.Axes, 'off');
            end
        end
        
        function ShowWaitCursor(obj)
            if isempty(obj.LastCursor)
                obj.LastCursor = get(obj.FigureHandle, 'Pointer');
            end
            
            set(obj.FigureHandle, 'Pointer', 'watch');
            drawnow;

        end
        
        function HideWaitCursor(obj)
            set(obj.FigureHandle, 'Pointer', obj.LastCursor);
            obj.LastCursor = [];
            drawnow;
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
            if ~isa(new_image, 'PTKImage')
                error('The image must be of class PTKImage');                
            end
            
            no_current_image = isempty(obj.ImageHandles{image_number});

            % Create an image handle if one doesn't already exist
            if isempty(obj.ImageHandles{image_number})
                if (image_number == 3)
                    obj.ImageHandles{image_number} = quiver([], [], [], [], 'Parent', obj.Axes, 'Color', 'red');
                else
                      obj.ImageHandles{image_number} = image([], 'Parent', obj.Axes);
                      axis(obj.Axes, 'off');
                      set(obj.Axes, 'YDir', 'reverse');
                end
            end
            
            % Update the panel
            if (image_number == 1 || no_current_image) % We need to set the axes initially, otherwise the overlay will not appear until UpdateAxes is called
                obj.ImageChanged;
            else                
                obj.OverlayImageChanged;
            end
            
            % Remove existing listeners
            if ~isempty(obj.ImageChangedListeners{image_number})
                delete (obj.ImageChangedListeners{image_number})
            end
            
            % Listen for image change events
            if (image_number == 1)
                obj.ImageChangedListeners{image_number} = addlistener(new_image, 'ImageChanged', @obj.ImageChangedCallback);
            else                
                obj.ImageChangedListeners{image_number} = addlistener(new_image, 'ImageChanged', @obj.OverlayImageChangedCallback);
            end
        end
        
        function UpdateAxes(obj)
            if (obj.BackgroundImage.ImageExists)                
                if ~isempty(obj.PreviousOrientation)
                    x_lim = get(obj.Axes, 'XLim');
                    y_lim = get(obj.Axes, 'YLim');
                    obj.AxisLimits{obj.PreviousOrientation}.XLim = x_lim;
                    obj.AxisLimits{obj.PreviousOrientation}.YLim = y_lim;
                end
                set(obj.Axes, 'Units', 'pixels');
                axes_position = get(obj.Axes, 'Position');
                axes_width_screenpixels = axes_position(3);
                axes_height_screenpixels = axes_position(4);
                image_size = obj.BackgroundImage.ImageSize;
                voxel_size = obj.BackgroundImage.VoxelSize;
                
                [dim_x_index, dim_y_index, dim_z_index] = obj.GetXYDimensionIndex;
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
                set(obj.Axes, 'XLim', x_lim, 'YLim', y_lim, 'DataAspectRatio', data_aspect_ratio);

                
                zoom(obj.Axes, 'reset');
                if ~isempty(obj.PreviousOrientation) && ~isempty(obj.AxisLimits{obj.Orientation})
                    x_lim = obj.AxisLimits{obj.Orientation}.XLim;
                    y_lim = obj.AxisLimits{obj.Orientation}.YLim;
                    set(obj.Axes, 'XLim', x_lim, 'YLim', y_lim);
                end
                obj.PreviousOrientation = obj.Orientation;

                if ~isempty(obj.ImageHandles{1})
                    set(obj.ImageHandles{1}, 'XData', x_range, 'YData', y_range);
                end
                if ~isempty(obj.ImageHandles{2})
                    overlay_offset_voxels = obj.GetOffsetVoxels(obj.OverlayImage);
                    overlay_offset_x_voxels = overlay_offset_voxels(dim_x_index);
                    overlay_offset_y_voxels = overlay_offset_voxels(dim_y_index);
                    set(obj.ImageHandles{2}, 'XData', x_range - overlay_offset_x_voxels, 'YData', y_range - overlay_offset_y_voxels);
                end
                if ~isempty(obj.ImageHandles{3})
                    quiver_offset_voxels = obj.GetOffsetVoxels(obj.QuiverImage);
                    quiver_offset_x_voxels = quiver_offset_voxels(dim_x_index);
                    quiver_offset_y_voxels = quiver_offset_voxels(dim_y_index);
                    
                    set(obj.ImageHandles{3}, 'XData', x_range - quiver_offset_x_voxels, 'YData', y_range - quiver_offset_y_voxels);
                end
            end
        end
        
        function offset_voxels = GetOffsetVoxels(obj, image_handle)
            if ~isempty(image_handle.GlobalOrigin) && ~isempty(obj.BackgroundImage.GlobalOrigin)
                offset_mm = image_handle.GlobalOrigin - obj.BackgroundImage.GlobalOrigin;
                offset_voxels = offset_mm./obj.BackgroundImage.VoxelSize;
            else
                offset_voxels = [0, 0, 0];
            end
        end
        
        function [dim_x_index dim_y_index dim_z_index] = GetXYDimensionIndex(obj)
            switch obj.Orientation
                case PTKImageOrientation.Coronal
                    dim_x_index = 2;
                    dim_y_index = 3;
                    dim_z_index = 1;
                case PTKImageOrientation.Sagittal
                    dim_x_index = 1;
                    dim_y_index = 3;
                    dim_z_index = 2;
                case PTKImageOrientation.Axial
                    dim_x_index = 2;
                    dim_y_index = 1;
                    dim_z_index = 3;
            end
        end
        
        function Resize(obj)
            set(obj.Parent, 'Units', 'Pixels');

            parent_position = get(obj.Parent, 'Position');
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
            set(obj.Axes, 'Units', 'Pixels', 'Position', [slice_slider_width axes_position axes_width axes_height]);
            set(obj.ControlPanel, 'Units', 'Pixels', 'Position', [1 1 control_panel_width control_panel_height]);
            set(obj.SliceSlider, 'Units', 'Pixels', 'Position', [0 control_panel_height slice_slider_width slice_slider_height]);

            % Add the 4 subpanels to the control panel
            button_width = 32;
            orientation_width = numel(obj.OrientationButtons)*button_width;
            mouse_controls_width = (obj.MouseControlButtons.Count)*button_width;
            mouse_controls_position = parent_width_pixels - mouse_controls_width + 1;
            central_panels_width = max(1, (parent_width_pixels - mouse_controls_width - orientation_width)/2);
            windowlevel_panel_position = orientation_width + central_panels_width + 1;
            set(obj.OrientationPanel, 'Units', 'Pixels', 'Position', [1 1 orientation_width control_panel_height]);
            set(obj.MouseControlPanel, 'Units', 'Pixels', 'Position', [mouse_controls_position 1 mouse_controls_width control_panel_height]);
            set(obj.ImageOverlayPanel, 'Units', 'Pixels', 'Position', [orientation_width+1 1 central_panels_width control_panel_height]);
            set(obj.WindowLevelPanel, 'Units', 'Pixels', 'Position', [windowlevel_panel_position 1 central_panels_width control_panel_height]);

            % Setup orientation panel
            set(obj.OrientationButtons(1), 'Units', 'Pixels', 'Position', [1 1 button_width  button_width]);
            set(obj.OrientationButtons(2), 'Units', 'Pixels', 'Position', [1+button_width 1 button_width button_width]);
            set(obj.OrientationButtons(3), 'Units', 'Pixels', 'Position', [1+button_width*2 1 button_width button_width]);

            % Setup mouse controls panel
            button_list = obj.MouseControlButtons.values;
            for button_index = 1 : obj.MouseControlButtons.Count
                button = button_list{button_index};
                set(button, 'Units', 'Pixels', 'Position', [1+button_width*(button_index - 1), 1, button_width, button_width]);
            end

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

            axis(obj.Axes, 'fill');
        end
        
        function UpdateStatus(obj)
            main_image = obj.BackgroundImage;
            overlay_image = obj.OverlayImage;
            
            if isempty(main_image) || ~main_image.ImageExists
                status_text = 'No image';
            else
                rescale_text = '';
                global_coords = obj.GetImageCoordinates;
                
                i_text = int2str(global_coords(1));
                j_text = int2str(global_coords(2));
                k_text = int2str(global_coords(3));
                    
                if (main_image.IsPointInImage(global_coords))
                    voxel_value = main_image.GetVoxel(global_coords);
                    if isinteger(voxel_value)
                        value_text = int2str(voxel_value);
                    else
                        value_text = num2str(voxel_value, 3);
                    end
                    
                    [rescale_value, rescale_units] = main_image.GetRescaledValue(global_coords);
                    if ~isempty(rescale_units) && ~isempty(rescale_value)
                        rescale_text = [rescale_units ':' int2str(rescale_value)];
                    end
                    
                    if isempty(overlay_image) || ~overlay_image.ImageExists || ~overlay_image.IsPointInImage(global_coords)
                        overlay_text = [];
                    else
                        overlay_voxel_value = overlay_image.GetVoxel(global_coords);
                        if isinteger(overlay_voxel_value)
                            overlay_value_text = int2str(overlay_voxel_value);
                        else
                            overlay_value_text = num2str(overlay_voxel_value, 3);
                        end
                        overlay_text = [' O:' overlay_value_text];
                    end
                else
                    overlay_text = '';
                    value_text = '-';
                    switch obj.Orientation
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
            set(obj.StatusText, 'String', status_text);
        end

        function global_coords = GetImageCoordinates(obj)
            coords = round(get(obj.Axes, 'CurrentPoint'));
            if (~isempty(coords))
                i_screen = coords(2,1);
                j_screen = coords(2,2);
                k_screen = obj.SliceNumber(obj.Orientation);
                
                switch obj.Orientation
                    case PTKImageOrientation.Coronal
                        i = k_screen;
                        j = i_screen;
                        k = j_screen;
                    case PTKImageOrientation.Sagittal
                        i = i_screen;
                        j = k_screen;
                        k = j_screen;
                    case PTKImageOrientation.Axial
                        i = j_screen;
                        j = i_screen;
                        k = k_screen;
                end
            else
                i = 1;
                j = 1;
                k = 1;
            end
            global_coords = obj.BackgroundImage.LocalToGlobalCoordinates([i, j, k]);
        end

        function screen_coords = GetScreenCoordinates(obj)
            coords = get(obj.Axes, 'CurrentPoint');
            if (~isempty(coords))
                i_screen = coords(2,1);
                j_screen = coords(2,2);
                screen_coords = [i_screen, j_screen];
            else
                screen_coords = [0, 0];
            end
        end

        function ClearAxesCache(obj)
            obj.PreviousOrientation = [];
            obj.AxisLimits = [];
            obj.AxisLimits{1} = {};
            obj.AxisLimits{2} = {};
            obj.AxisLimits{3} = {};
        end
        
        % This function should be called when the image is
        % changed
        function ImageChanged(obj)
            obj.ClearAxesCache;
            obj.AutoChangeOrientation;
            obj.UpdateAxes;
            obj.UpdateGuiForNewImage;
            obj.UpdateGuiForNewOrientation;
            obj.UpdateGui;
            obj.DrawImages(true, false, false);
            obj.UpdateStatus;
            
            for tool_set = obj.Tools.values
                tool_set{1}.ImageChanged;
            end
        end

        % This function should be called when the orientation is
        % changed
        function OrientationChanged(obj)
            obj.UpdateAxes;
            obj.UpdateGuiForNewOrientation;
            obj.UpdateGui;
            obj.DrawImages(true, true, true);
            obj.UpdateStatus;
            
            for tool_set = obj.Tools.values
                tool_set{1}.NewSliceOrOrientation;
            end
        end
            

        function OverlayImageChanged(obj)
            obj.UpdateAxes;
            obj.DrawImages(false, true, false);
            
            for tool_set = obj.Tools.values
                tool_set{1}.OverlayImageChanged;
            end
            
        end
        
        function UpdateGuiForNewImage(obj)
            main_image = obj.BackgroundImage;
            if ~isempty(main_image) && main_image.ImageExists
                set(obj.OpacitySlider, 'Min', 0);
                set(obj.OpacitySlider, 'Max', 100);
                limits = main_image.Limits;
                limits_hu = main_image.GrayscaleToRescaled(limits);
                if ~isempty(limits_hu)
                    limits = limits_hu;
                end

                set(obj.WindowSlider, 'Min', 0);
                set(obj.WindowSlider, 'Max', max(1, 3*(limits(2) - limits(1))));
                if obj.Window < 0
                    obj.Window = 0;
                end
                if obj.Window > max(1, limits(2) - limits(1))
                    obj.Window = max(1, limits(2) - limits(1));
                end
                
                set(obj.LevelSlider, 'Min', limits(1));
                set(obj.LevelSlider, 'Max', max(limits(1)+1, limits(2)));
                if obj.Level < limits(1)
                    obj.Level = limits(1);
                end
                if obj.Level > limits(2)
                    obj.Level = limits(2);
                end
            end
        end
        
        function UpdateGuiForNewOrientation(obj)
            main_image = obj.BackgroundImage;
            if ~isempty(main_image) && main_image.ImageExists
                
                image_size = main_image.ImageSize;
                slider_max =  max(2, image_size(obj.Orientation));
                slider_min = 1;
                if obj.SliceNumber(obj.Orientation) > image_size(obj.Orientation)
                    obj.SliceNumber(obj.Orientation) = image_size(obj.Orientation);
                end
                if obj.SliceNumber(obj.Orientation) < 1
                    obj.SliceNumber(obj.Orientation) = 1;
                end
                
                set(obj.SliceSlider, 'Min', slider_min);

                current_slice_value = get(obj.SliceSlider, 'Value');
                if (current_slice_value ~= obj.SliceNumber(obj.Orientation))
                    set(obj.SliceSlider, 'Value', obj.SliceNumber(obj.Orientation));
                end
                
                set(obj.SliceSlider, 'Max', slider_max);
                set(obj.SliceSlider, 'SliderStep', [1/(slider_max - slider_min), 10/(slider_max-slider_min)]);
            end
        end
        
        % This function is used to change the max window and min/max level
        % values after the window or level has been changed to a value outside
        % of the limits
        function ModifyWindowLevelLimits(obj)
            if obj.Level > get(obj.LevelSlider, 'Max')
                set(obj.LevelSlider, 'Max', obj.Level);
            end
            if obj.Level < get(obj.LevelSlider, 'Min')
                set(obj.LevelSlider, 'Min', obj.Level);
            end
            if obj.Window > get(obj.WindowSlider, 'Max')
                set(obj.WindowSlider, 'Max', obj.Window);
            end
            if obj.Window < 0
                obj.Window = 0;
            end
        end
     
        function UpdateGui(obj)
            set(obj.OverlayCheckbox, 'Value', obj.ShowOverlay);
            set(obj.ImageCheckbox, 'Value', obj.ShowImage);
            set(obj.OrientationButtons(obj.Orientation), 'Value', 1);
            set(obj.MouseControlButtons(obj.SelectedControl), 'Value', 1);
            
            main_image = obj.BackgroundImage;
            if ~isempty(main_image) && main_image.ImageExists
                set(obj.WindowEditbox, 'String', num2str(obj.Window));
                set(obj.WindowSlider, 'Value', obj.Window);
                set(obj.LevelEditbox, 'String', num2str(obj.Level));
                set(obj.LevelSlider, 'Value', obj.Level);
                set(obj.OpacitySlider, 'Value', obj.OverlayOpacity);
                
                image_size = main_image.ImageSize;
                if obj.SliceNumber(obj.Orientation) > image_size(obj.Orientation)
                    obj.SliceNumber(obj.Orientation) = image_size(obj.Orientation);
                end
                if obj.SliceNumber(obj.Orientation) < 1
                    obj.SliceNumber(obj.Orientation) = 1;
                end
                current_slice_value = get(obj.SliceSlider, 'Value');
                if (current_slice_value ~= obj.SliceNumber(obj.Orientation))
                    set(obj.SliceSlider, 'Value', obj.SliceNumber(obj.Orientation));
                end

            end
        end
                
        function image_slice = GetImageSlice(obj, image_object)
            offset_voxels = obj.GetOffsetVoxels(image_object);
            slice_number = obj.SliceNumber(obj.Orientation) - round(offset_voxels(obj.Orientation));
            if (slice_number < 1) || (slice_number > image_object.ImageSize(obj.Orientation))
                image_slice = image_object.GetBlankSlice(obj.Orientation);
            else
                image_slice = image_object.GetSlice(slice_number, obj.Orientation);
            end
            if (obj.Orientation ~= PTKImageOrientation.Axial)
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
                        case PTKImageOrientation.Coronal
                            xy = [2 3];
                        case PTKImageOrientation.Sagittal
                            xy = [1 3];
                        case PTKImageOrientation.Axial
                            xy = [2 1];
                    end
                    x_range = 1 : image_size(xy(1));
                    y_range = 1 : image_size(xy(2));
                    
                    % Create an image handle if one doesn't already exist
                    if isempty(obj.ImageHandles{image_number})
                        obj.ImageHandles{3} = quiver([], [], [], [], 'Parent', obj.Axes, 'Color', 'red');
                    end
                     
                    set(obj.ImageHandles{image_number}, 'XData', x_range);
                    set(obj.ImageHandles{image_number}, 'YData', y_range);
                    if quiver_on
                        set(obj.ImageHandles{image_number}, 'UData', qs(:, :, xy(1)));
                        set(obj.ImageHandles{image_number}, 'VData', qs(:, :, xy(2)));
                        set(obj.ImageHandles{image_number}, 'Visible', 'on')
                    else
                       set(obj.ImageHandles{image_number}, 'UData', []);
                       set(obj.ImageHandles{image_number}, 'VData', []);
                       set(obj.ImageHandles{image_number}, 'Visible', 'off')
                    end

                else
                    set(obj.ImageHandles{image_number}, 'UData', []);
                    set(obj.ImageHandles{image_number}, 'VData', []);
                    set(obj.ImageHandles{image_number}, 'Visible', 'off')
                end
            end            
        end

        function slice = GetQuiverSlice(obj, image_object, slice_number)
            switch obj.Orientation
                case PTKImageOrientation.Coronal
                    slice = squeeze(image_object.RawImage(slice_number, :, :, :));
                case PTKImageOrientation.Sagittal
                    slice = squeeze(image_object.RawImage(:, slice_number, :, :));
                case PTKImageOrientation.Axial
                    slice = squeeze(image_object.RawImage(:, :, slice_number, :));
                otherwise
                    error('Unsupported dimension');
            end
            if (obj.Orientation ~= PTKImageOrientation.Axial)
                slice = permute(slice, [2 1 3]);
            end
        end
            
        function DrawImage(obj, image_number, opacity, image_object)
            if ~isempty(image_object)
                if image_object.ImageExists
                    image_slice = obj.GetImageSlice(image_object);
                    image_type = image_object.ImageType;

                    if (image_type == PTKImageType.Scaled)
                        limits = image_object.Limits;
                    elseif (image_type == PTKImageType.Colormap)
                        
                        % For unsigned types, we don't need the limits (see GetImage() below)
                        if isa(image_slice, 'uint8') || isa(image_slice, 'uint16')
                            limits = [];
                        else
                            limits = image_object.Limits;
                        end
                    else
                        limits = [];
                    end

                    level_grayscale = image_object.RescaledToGrayscale(obj.Level);
                    window_grayscale = obj.Window;
                    if isa(image_object, 'PTKDicomImage')
                        if image_object.IsCT && ~isempty(image_object.RescaleSlope)
                            window_grayscale = window_grayscale/image_object.RescaleSlope;
                        end
                    end

                    [rgb_slice, alpha_slice] = obj.GetImage(image_slice, limits, image_type, window_grayscale, level_grayscale, obj.BlackIsTransparent, image_object.ColorLabelMap);
                    alpha_slice = double(alpha_slice)*opacity/100;
                    
                    % Special code to highlight one colour
                    if ~isempty(obj.OpaqueColour)
                        alpha_slice(image_slice == obj.OpaqueColour) = 1;
                    end

                    if isempty(obj.ImageHandles{image_number})
                        obj.ImageHandles{image_number} = imshow([], 'Parent', obj.Axes);
                    end
                    
                    set(obj.ImageHandles{image_number}, 'CData', rgb_slice);
                    set(obj.ImageHandles{image_number}, 'AlphaData', alpha_slice);
                    set(obj.ImageHandles{image_number},'AlphaDataMapping','none');
                else
                    set(obj.ImageHandles{image_number}, 'CData', []);                    
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
            
            % If the window or level values have been externally set outside the
            % slider range, then we modify the slider range to accommodate this
            obj.ModifyWindowLevelLimits;
            
            obj.UpdateGui;
            obj.DrawImages(true, true, true);
            obj.UpdateStatus;
        end
        
        % Slice number has changed
        function SliceNumberChangedCallback(obj, ~, ~, ~)
            obj.UpdateGui;
            
            for tool_set = obj.Tools.values
                tool_set{1}.NewSliceOrOrientation;
            end
            
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
        
        % Mouse has moved over the figure
        function MouseHasMoved(obj, hObject, eventData)
            screen_coords = obj.GetScreenCoordinates;
            last_coords = obj.LastCoordinates;
            selection_type = get(hObject, 'SelectionType');
            mouse_is_down = obj.MouseIsDown;
            
            tool = obj.GetCurrentTool(mouse_is_down, selection_type);
            tool.MouseHasMoved(obj, screen_coords, last_coords, mouse_is_down);
            
            obj.UpdateCursor(hObject, mouse_is_down, selection_type);
            obj.UpdateStatus();
            if (~isempty(obj.WindowButtonMotionFcn))
                obj.WindowButtonMotionFcn(hObject, eventData);
            end
        end
        
        function UpdateCursor(obj, hObject, mouse_is_down, keyboard_modifier)
            global_coords = obj.GetImageCoordinates;
            point_is_in_image = obj.BackgroundImage.IsPointInImage(global_coords);
            if (~point_is_in_image)
                obj.MouseIsDown = false;
            end
            
            if point_is_in_image
                current_tool = obj.GetCurrentTool(mouse_is_down, keyboard_modifier);
                new_cursor = current_tool.Cursor;
            else
                new_cursor = 'arrow';
            end
            
            if ~strcmp(obj.CurrentCursor, new_cursor)
                set(hObject, 'Pointer', new_cursor);
                obj.CurrentCursor = new_cursor;
            end
            
        end
        
        % Returns the tool whch is currently selected. If keyboard_modifier is
        % specified, then this may override the current tool
        function tool = GetCurrentTool(obj, mouse_is_down, keyboard_modifier)
            if ~isempty(keyboard_modifier) && ~isempty(mouse_is_down) && mouse_is_down
                if strcmp(keyboard_modifier, 'extend')
                    tool = obj.PanTool;
                    return;
                elseif strcmp(keyboard_modifier, 'alt')
                    tool = obj.ZoomTool;
                    return;
                end
            end
            tool = obj.Tools(obj.SelectedControl);
        end
                

        % Mouse has been clicked
        function MouseDown(obj, src, ~)
            screen_coords = obj.GetScreenCoordinates;
            obj.LastCoordinates = screen_coords;
            obj.MouseIsDown = true;
            selection_type = get(src, 'SelectionType');
            tool = obj.GetCurrentTool(true, selection_type);
            global_coords = obj.GetImageCoordinates;
            if (obj.BackgroundImage.IsPointInImage(global_coords))
                tool.MouseDown(screen_coords);
                obj.ToolOnMouseDown = tool;
            else
                notify(obj, 'MouseClickInImage', PTKEventData(global_coords));
                obj.ToolOnMouseDown = [];
            end

            obj.UpdateCursor(src, true, selection_type);
        end

        % Mouse has been clicked
        function MouseUp(obj, src, ~)
            obj.MouseIsDown = false;
            screen_coords = obj.GetScreenCoordinates;
            obj.LastCoordinates = screen_coords;
            selection_type = get(src, 'SelectionType');

            tool = obj.ToolOnMouseDown;
            if ~isempty(tool)
                global_coords = obj.GetImageCoordinates;
                if (obj.BackgroundImage.IsPointInImage(global_coords))
                    tool.MouseUp(screen_coords);
                    obj.ToolOnMouseDown = [];
                end
            end
            obj.UpdateCursor(src, false, selection_type);
        end
        
        % Key has been clicked
        function KeyPressed(obj, ~, eventdata)
            obj.ShortcutKeys(eventdata.Key);
        end
        
        function ShortcutKeys(obj, key)
            if strcmpi(key, 'c')
                obj.Orientation = PTKImageOrientation.Coronal;
            elseif strcmpi(key, 's')
                obj.Orientation = PTKImageOrientation.Sagittal;
            elseif strcmpi(key, 'a')
                obj.Orientation = PTKImageOrientation.Axial;
            elseif strcmpi(key, 'i')
                obj.ShowImage = ~obj.ShowImage;
            elseif strcmpi(key, 't')
                obj.BlackIsTransparent = ~obj.BlackIsTransparent;
            elseif strcmpi(key, 'o')
                obj.ShowOverlay = ~obj.ShowOverlay;
            elseif strcmpi(key, 'downarrow')
                obj.SliceNumber(obj.Orientation) = obj.SliceNumber(obj.Orientation) + 1;
            elseif strcmpi(key, 'uparrow')
                obj.SliceNumber(obj.Orientation) = obj.SliceNumber(obj.Orientation) - 1;
            else
                % Shortcuts for selecting tools
                for tool = obj.Tools.values
                    if strcmpi(key, tool{1}.ShortcutKey)
                        obj.SetControl(tool{1}.Tag);
                        return
                    end
                end
                obj.Tools(obj.SelectedControl).Keypress(key);
            end
        end
        
        function OrientationCallback(obj, ~, eventdata, ~)
            switch get(eventdata.NewValue, 'Tag')
                case 'Coronal'
                    obj.Orientation = PTKImageOrientation.Coronal;
                case 'Sagittal'
                    obj.Orientation = PTKImageOrientation.Sagittal;
                case 'Axial'
                    obj.Orientation = PTKImageOrientation.Axial;
            end
        end
        
        
        
        function SliderCallback(obj, hObject, ~)
            obj.SliceNumber(obj.Orientation) = round(get(hObject,'Value'));
        end

        function OpacitySliderCallback(obj, hObject, ~, ~)
            obj.OverlayOpacity = get(hObject,'Value');
            if ~obj.ShowOverlay
                obj.ShowOverlay = true;
            end
        end
        
        function CustomResize(obj, eventdata, handles)
            obj.Resize;
            if (~isempty(obj.ResizeFunction))
                obj.ResizeFunction(eventdata, handles);
            end
        end
        
        function SetControl(obj, tag_value)
            obj.SelectedControl = tag_value;
            tool = obj.Tools(tag_value);
            
            % Matlab tools require the keypress callback to be reset
            if tool.RestoreKeyPressCallbackWhenSelected
                obj.RestoreKeyPressCallback;
            end
            
            % Change the cursor
            obj.UpdateCursor(obj.FigureHandle, [], []);
            
            % Run the code to enable or disable tools
            obj.UpdateTools;
            
            % Enable the button for this tool
            set(obj.MouseControlButtons(tag_value), 'Value', 1);
        end
        
        function UpdateTools(obj)
            tool_list = obj.Tools.values;
            for tool_set = tool_list
                tool = tool_set{1};
                tool_is_enabled = strcmp(obj.SelectedControl, tool.Tag);
                tool.Enable(tool_is_enabled);
                if tool_is_enabled
                    set(obj.Axes, 'uicontextmenu', tool.ContextMenu);
                end
            end
        end

        function ControlsCallback(obj, ~, eventdata, ~)
            obj.SetControl(get(eventdata.NewValue, 'Tag'));
        end
        

% TODO
%         % Executes when figure closes, to ensure the listeners are removed
%         function CustomCloseFunction(obj, ~, ~)
%             obj.DeleteImageChangedListeners;
%             delete(obj);
%         end
%         
        function DeleteImageChangedListeners(obj)
            for image_number = 1 : 3
                if ~isempty(obj.ImageChangedListeners{image_number})
                    delete(obj.ImageChangedListeners{image_number});
                    obj.ImageChangedListeners{image_number} = [];
                end
            end            
        end

        function AutoChangeOrientation(obj)
            orientation = obj.BackgroundImage.Find2DOrientation;
            if ~isempty(orientation)
                obj.Orientation = orientation;
            end
        end

    end
    
    
    methods (Access = private, Static)
        
        function [rgb_slice, alpha_slice] = GetImage(image_slice, limits, image_type, window, level, black_is_transparent, map)
            switch image_type
                case PTKImageType.Grayscale
                    rescaled_image_slice = PTKViewerPanel.RescaleImage(image_slice, window, level);
                    [rgb_slice, alpha_slice] = PTKViewerPanel.GetBWImage(rescaled_image_slice);
                case PTKImageType.Colormap
                    
                    % An empty limits indicates the value should never be below zero. This saves
                    % having to fetch the actual limits in the calling function, which is slow if
                    % done interactively
                    if ~isempty(limits) && limits(1) < 0
                        image_slice = image_slice - limits(1);
                    end
                    [rgb_slice, alpha_slice] = PTKViewerPanel.GetLabeledImage(image_slice, map);
                case PTKImageType.Scaled
                    [rgb_slice, alpha_slice] = PTKViewerPanel.GetColourMap(image_slice, limits, black_is_transparent);
            end
            
        end
        
        function [rgb_image, alpha] = GetBWImage(image)
            rgb_image = (cat(3, image, image, image));
            alpha = ones(size(image));
        end

        function [rgb_image, alpha] = GetLabeledImage(image, map)
            if isempty(map)
                if isa(image, 'double') || isa(image, 'single')
                    rgb_image = label2rgb(round(image), 'lines');
                else
                    rgb_image = label2rgb(image, 'lines');
                end
            else
                if isa(image, 'double') || isa(image, 'single')
                    rgb_image = label2rgb(map(round(image + 1)), 'lines');
                else
                    rgb_image = label2rgb(map(image + 1), 'lines');
                end
            end
            alpha = int8(image ~= 0);
        end

        function [rgb_image, alpha] = GetColourMap(image, image_limits, black_is_transparent)
            image_limits(1) = min(-1, image_limits(1));
            image_limits(2) = max(1, image_limits(2));
            positive_mask = image >= 0;
            rgb_image = zeros([size(image), 3], 'uint8');
            positive_image = abs(double(image))/abs(double(image_limits(2)));
            negative_image = abs(double(image))/abs(double(image_limits(1)));
            rgb_image(:, :, 1) = uint8(positive_mask).*(uint8(255*positive_image));
            rgb_image(:, :, 3) = uint8(~positive_mask).*(uint8(255*negative_image));
            
            if black_is_transparent
                alpha = double(positive_mask).*positive_image + single(~positive_mask).*negative_image;
                rgb_image(:, :, 1) = 255*uint8(positive_mask);
                rgb_image(:, :, 3) = 255*uint8(~positive_mask);
            else
                alpha = ones(size(image));
            end
        end
        
        function rescaled_image = RescaleImage(image, window, level)
            min_value = double(level) - double(window)/2;
            max_value = double(level) + double(window)/2;
            scale_factor = 255/max(1, (max_value - min_value));
            rescaled_image = uint8(min(((image - min_value)*scale_factor), 255));
        end
        
    end
end

