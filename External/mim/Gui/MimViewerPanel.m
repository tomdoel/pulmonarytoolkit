classdef MimViewerPanel < GemPanel
    % MimViewerPanel. Creates a data viewer window for imaging 3D data slice-by-slice.
    %
    %     MimViewerPanel creates a visualisation window on the supplied
    %     graphics handle. It creates the viewer panel, scrollbar, orientation
    %     and tool controls, a status window and controls for toggling the image
    %     and overlay on and off and changing overlay transparency.
    %
    %     MimViewerPanel is used as a component by the standalong data viewer
    %     application PTKViewer, and by the Pulmonary Toolkit gui application.
    %     You can also use this in your own user interfaces.
    %
    %     New background, overlay and quiver plots can be viewed by assigning
    %     images (within a PTKViewer class) to the BackgroundImage, OverlayImage
    %     and QuiverImage properties.
    %
    %     See PTKViewer.m for a simple example of how to use this class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    events
        MouseCursorStatusChanged % An event to indicate if the MouseCursorStatus property has changed
    end
    
    properties (SetObservable)
        SelectedControl = 'W/L'    % The currently selected tool
        SliceSkip = 10         % Number of slices skipped when navigating throough images with the space key
        PaintBrushSize = 5     % Size of the paint brush used by the ReplaceColourTool
        NewMarkerColour        % The current colour of new marker points
    end
    
    properties (Dependent)
        BackgroundImage        % The greyscale image
        OverlayImage           % The colour transparent overlay image
        QuiverImage            % A vector quiver plot showing directions
        SliceNumber            % The currently shown slice in 3 dimensions
        Orientation            % The currently selected image orientation
        Window                 % The image window (in HU for CT images)
        Level                  % The image level (in HU for CT images)
        OverlayOpacity         % Sets the opacity percentage of the transparent overlay image
        ShowImage              % Sets whether the greyscale image is visible or invisible
        ShowOverlay            % Sets whether the transparent overlay image is visible or invisible
        ShowMarkers            % Sets whether marker points are visible or invisible
        BlackIsTransparent     % Sets whether black in the transparent overlay image is transparent or shown as black
        OpaqueColour           % If set, then this colour will always be shown at full opacity in the overlay
    end
    
    properties (SetObservable, SetAccess = private)
        WindowLimits           % The limits of the image window (in HU for CT images)  
        LevelLimits            % The limits of the image level (in HU for CT images)  
    end
    
    properties (SetAccess = private)
        % Image volume models
        BackgroundImageSource
        OverlayImageSource
        QuiverImageSource
        MarkerImageSource
        
        % Slice number and orientation model
        ImageSliceParameters
        
        % Visualisation property models
        BackgroundImageDisplayParameters
        OverlayImageDisplayParameters
        MarkerImageDisplayParameters

        Mode = ''              % Specifies the current editing mode
        SubMode = ''           % Specifies the current editing submode
        EditFixedOuterBoundary % Specifies whether the current edit can modify the segmentation outer boundary
        MouseCursorStatus      % A class of type MimMouseCursorStatus showing data representing the voxel under the cursor
        
        BackgroundLayer
        SegmentationLayer
        QuiverLayer
        MarkerLayer
    end
    
    properties (Access = private)
        LevelMin
        LevelMax
        WindowMin
        WindowMax
        
        ToolCallback
        ViewerPanelCallback
        ImageOverlayAxes
        CinePanel2D
    end
    
    properties (Access = protected)
        ViewerPanelMultiView
        Tools
    end
    
    properties
        DefaultOrientation = PTKImageOrientation.Axial
    end
    
    methods
        
        function obj = MimViewerPanel(parent)
            % Creates a MimViewerPanel
            
            obj = obj@GemPanel(parent);
            
            obj.MouseCursorStatus = MimMouseCursorStatus;

            % Create the image pointer wrappers
            obj.BackgroundImageSource = GemImageSource;
            obj.OverlayImageSource = GemImageSource;
            obj.QuiverImageSource = GemImageSource;
            obj.MarkerImageSource = GemMarkerPointImage;
            
            % Create the model object that holds the slice number and
            % orientation
            obj.ImageSliceParameters = GemImageSliceParameters;
            
            % Create the model objects that hold visualisation parameters
            % for each of the images
            obj.BackgroundImageDisplayParameters = GemImageDisplayParameters;
            obj.OverlayImageDisplayParameters = GemImageDisplayParameters;
            obj.OverlayImageDisplayParameters.Opacity = 50;
            obj.OverlayImageDisplayParameters.BlackIsTransparent = true;
            obj.MarkerImageDisplayParameters = GemMarkerDisplayParameters;

            % Create the panel which contains the 2D image viewer
            obj.ViewerPanelMultiView = GemViewerPanelMultiView(obj);

            % Create the axes on which the 2D images and overlay are drawn
            obj.ImageOverlayAxes = GemImageAxes(obj.ViewerPanelMultiView, obj.GetBackgroundImageSource, obj.GetImageSliceParameters);
            
            % Create the image layers
            obj.BackgroundLayer = MimImageLayer(obj.ImageOverlayAxes, obj.GetBackgroundImageSource, obj.GetImageSliceParameters,  obj.GetBackgroundImageDisplayParameters, obj.GetBackgroundImageSource);
            obj.ImageOverlayAxes.AddChild(obj.BackgroundLayer);
            obj.SegmentationLayer = MimImageLayer(obj.ImageOverlayAxes, obj.GetOverlayImageSource, obj.GetImageSliceParameters, obj.GetOverlayImageDisplayParameters, obj.GetBackgroundImageSource);
            obj.ImageOverlayAxes.AddChild(obj.SegmentationLayer);
            obj.QuiverLayer = MimQuiverImageLayer(obj.ImageOverlayAxes, obj.GetQuiverImageSource, obj.GetImageSliceParameters, obj.GetOverlayImageDisplayParameters, obj.GetBackgroundImageSource);
            obj.ImageOverlayAxes.AddChild(obj.QuiverLayer);
            
            % Create the object which handles the marker image processing in the viewer
            obj.MarkerLayer = GemMarkerLayer(obj.ImageOverlayAxes, obj.MarkerImageSource, obj.GetImageSliceParameters, obj.GetMarkerImageDisplayParameters, obj.GetBackgroundImageSource);

            % Create the mouse tools
            obj.ToolCallback = MimToolCallback(obj, obj.BackgroundImageDisplayParameters, obj.ImageOverlayAxes, obj.Reporting);
            obj.Tools = MimToolList(obj.MarkerLayer, obj.ToolCallback, obj, obj.ImageSliceParameters, obj.BackgroundImageDisplayParameters);

            % Create the scrolling 2D cine view and tools and add to the
            % multiview panel
            obj.CinePanel2D = MimCinePanelWithTools(obj.ViewerPanelMultiView, obj.Tools, obj.ImageOverlayAxes, obj.GetBackgroundImageSource, obj.ImageSliceParameters);
            obj.ViewerPanelMultiView.Add2DCinePanel(obj.CinePanel2D, obj.Reporting);

            obj.AddChild(obj.ViewerPanelMultiView);
        end
        
        function background_image = GetBackgroundImageSource(obj)
            background_image = obj.BackgroundImageSource;
        end
        
        function background_image = GetOverlayImageSource(obj)
            background_image = obj.OverlayImageSource;
        end
        
        function quiver_image = GetQuiverImageSource(obj)
            quiver_image = obj.QuiverImageSource;
        end
        
        function image_slice_parameters = GetImageSliceParameters(obj)
            image_slice_parameters = obj.ImageSliceParameters;
        end
        
        function image_display_parameters = GetBackgroundImageDisplayParameters(obj)
            image_display_parameters = obj.BackgroundImageDisplayParameters;
        end
        
        function image_display_parameters = GetOverlayImageDisplayParameters(obj)
            image_display_parameters = obj.OverlayImageDisplayParameters;
        end
        
        function image_display_parameters = GetMarkerImageDisplayParameters(obj)
            image_display_parameters = obj.MarkerImageDisplayParameters;
        end
        
        function Resize(obj, position)
            % Resize the viewer panel and its subcomponents
            
            Resize@GemPanel(obj, position);
            
            % Position axes and slice slider
            parent_width_pixels = position(3);
            parent_height_pixels = position(4);
            image_width = parent_width_pixels;
            
            image_height = max(1, parent_height_pixels);
            image_panel_position = [1, 1, image_width, image_height];
            
            % Resize the image and slider
            obj.ViewerPanelMultiView.Resize(image_panel_position);
        end
        
        function marker_layer = GetMarkerLayer(obj)
            % Returns a pointer to the GemMarkerLayer object
            
            marker_layer = obj.MarkerLayer;
        end
        
        function ClearOverlays(obj)
            % Erase the image in the transparent overlay
            
            obj.OverlayImage.Title = [];
            obj.OverlayImage.Reset;
            obj.QuiverImage.Reset;
        end
        
        function in_marker_mode = IsInMarkerMode(obj)
            % Returns true if the viewer panel is currently in marker editing mode
            
            in_marker_mode = strcmp(obj.SelectedControl, 'Mark');
        end

        function in_edit_mode = IsInEditMode(obj)
            % Returns true if the viewer panel is currently in segmentation editing mode
            
            in_edit_mode = strcmp(obj.SelectedControl, 'Edit');
        end
        
        function ZoomTo(obj, i_limits, j_limits, k_limits)
            % Changes the current axis limits to the specified global coordinates
            % i_limits = [minimum_i, maximum_i] and the same for j, k.

            obj.ViewerPanelMultiView.ZoomTo(i_limits, j_limits, k_limits);
        end
        
        function frame = Capture(obj)
            % Captures a 2D image from the currently displayed slice
            
            frame = obj.ViewerPanelMultiView.Capture(obj.BackgroundImage.ImageSize, obj.Orientation);
        end

        function SetControl(obj, tag_value)
            % Changes the active tool, specified by tag string, e.g. 'Cine'
            
            obj.SelectedControl = tag_value;
        end
        
        function SetModes(obj, mode, submode)
            % Changes the active edit mode and submode
            
            obj.Mode = mode;
            obj.SubMode = submode;
            
            if strcmp(mode, MimModes.EditMode)
                if strcmp(submode, MimSubModes.PaintEditing)
                    obj.SetControl('Paint');
                elseif strcmp(submode, MimSubModes.ColourRemapEditing)
                    obj.SetControl('Map');
                elseif strcmp(submode, MimSubModes.EditBoundariesEditing)
                    obj.SetControl('Edit');
                elseif strcmp(submode, MimSubModes.FixedBoundariesEditing)
                    obj.SetControl('Edit');
                else
                    obj.SetControl('W/L');
                end
            else
                obj.SetControl('W/L');
            end
        end
        
        function input_has_been_processed = ShortcutKeys(obj, key)
            % Process shortcut keys for the viewer panel.
            
            % First deal with priority shortcut keys for the panel
            if strcmpi(key, 'downarrow')
                obj.SliceNumber(obj.Orientation) = obj.SliceNumber(obj.Orientation) + 1;
                input_has_been_processed = true;
            elseif strcmpi(key, 'uparrow')
                obj.SliceNumber(obj.Orientation) = obj.SliceNumber(obj.Orientation) - 1;
                input_has_been_processed = true;
            elseif strcmpi(key, 'c')
                obj.Orientation = PTKImageOrientation.Coronal;
                input_has_been_processed = true;
            elseif strcmpi(key, 's')
                obj.Orientation = PTKImageOrientation.Sagittal;
                input_has_been_processed = true;
            elseif strcmpi(key, 'a')
                obj.Orientation = PTKImageOrientation.Axial;
                input_has_been_processed = true;
            elseif strcmpi(key, 'i')
                obj.ShowImage = ~obj.ShowImage;
                input_has_been_processed = true;
            elseif strcmpi(key, 't')
                obj.BlackIsTransparent = ~obj.BlackIsTransparent;
                input_has_been_processed = true;
            elseif strcmpi(key, 'o')
                obj.ShowOverlay = ~obj.ShowOverlay;
                input_has_been_processed = true;
            elseif strcmpi(key, 'l') % L
                obj.MarkerImageDisplayParameters.ShowLabels = ~obj.MarkerImageDisplayParameters.ShowLabels;
                input_has_been_processed = true;
            else
                input_has_been_processed = obj.Tools.ShortcutKeys(key, obj.SelectedControl);
            end
        end
     
        function SetWindowLimits(obj, window_min, window_max)
            % Sets the minimum and maximum values for the level slider
            
            obj.WindowLimits = [window_min, window_max];
        end
        
        function SetLevelLimits(obj, level_min, level_max)
            % Sets the minimum and maximum values for the level slider
            
            obj.LevelLimits = [level_min, level_max];
        end
        
        function tool = GetCurrentTool(obj, mouse_is_down, keyboard_modifier)
            % Returns the currently enabled mouse tool
            
            tool = obj.Tools.GetCurrentTool(mouse_is_down, keyboard_modifier, obj.SelectedControl);
        end
        
        function tools = GetToolList(obj)
            % Returns a MimToolList describing the mouse tools supported by the viewer
            
            tools = obj.Tools;
        end

        function set.BackgroundImage(obj, new_image)
            obj.BackgroundImageSource.Image = new_image;
        end
        
        function current_image = get.BackgroundImage(obj)
            current_image = obj.BackgroundImageSource.Image;
        end
        
        function set.OverlayImage(obj, new_image)
            obj.OverlayImageSource.Image = new_image;
        end
        
        function current_image = get.OverlayImage(obj)
            current_image = obj.OverlayImageSource.Image;
        end
        
        function set.QuiverImage(obj, new_image)
            obj.QuiverImageSource.Image = new_image;
        end
        
        function current_image = get.QuiverImage(obj)
            current_image = obj.QuiverImageSource.Image;
        end
        
        function set.SliceNumber(obj, slice_number)
            obj.ImageSliceParameters.SliceNumber = slice_number;
        end
        
        function slice_number = get.SliceNumber(obj)
            slice_number = obj.ImageSliceParameters.SliceNumber;
        end        
        
        function set.Orientation(obj, orientation)
            obj.ImageSliceParameters.Orientation = orientation;
        end
        
        function orientation = get.Orientation(obj)
            orientation = obj.ImageSliceParameters.Orientation;
        end
        
        function set.OverlayOpacity(obj, opacity)
            obj.OverlayImageDisplayParameters.Opacity = opacity;
        end
        
        function opacity = get.OverlayOpacity(obj)
            opacity = obj.OverlayImageDisplayParameters.Opacity;
        end        
        
        function set.ShowImage(obj, show_image)
            obj.BackgroundImageDisplayParameters.ShowImage = show_image;
        end
        
        function show_image = get.ShowImage(obj)
            show_image = obj.BackgroundImageDisplayParameters.ShowImage;
        end
        
        function set.Window(obj, window)
            obj.BackgroundImageDisplayParameters.Window = window;
            obj.OverlayImageDisplayParameters.Window = window;
        end
        
        function level = get.Level(obj)
            level = obj.BackgroundImageDisplayParameters.Level;
        end
        
        function set.Level(obj, level)
            obj.BackgroundImageDisplayParameters.Level = level;
            obj.OverlayImageDisplayParameters.Level = level;
        end
        
        function window = get.Window(obj)
            window = obj.BackgroundImageDisplayParameters.Window;
        end
        
        function set.ShowOverlay(obj, show_image)
            obj.OverlayImageDisplayParameters.ShowImage = show_image;
        end
        
        function show_image = get.ShowOverlay(obj)
            show_image = obj.OverlayImageDisplayParameters.ShowImage;
        end
        
        function set.ShowMarkers(obj, show_markers)
            obj.MarkerImageDisplayParameters.ShowMarkers = show_markers;
        end
        
        function show_markers = get.ShowMarkers(obj)
            show_markers = obj.MarkerImageDisplayParameters.ShowMarkers;
        end
        
        function set.BlackIsTransparent(obj, black_is_transparent)
            obj.OverlayImageDisplayParameters.BlackIsTransparent = black_is_transparent;
        end
        
        function black_is_transparent = get.BlackIsTransparent(obj)
            black_is_transparent = obj.OverlayImageDisplayParameters.BlackIsTransparent;
        end
        
        function set.OpaqueColour(obj, opaque_colour)
            obj.OverlayImageDisplayParameters.OpaqueColour = opaque_colour;
        end
        
        function opaque_colour = get.OpaqueColour(obj)
            opaque_colour = obj.OverlayImageDisplayParameters.OpaqueColour;
        end
        
        function GotoPreviousMarker(obj)
        % Find the image slice containing the last marker
            
            maximum_skip = obj.SliceSkip;
            orientation = obj.Orientation;
            current_coordinate = obj.SliceNumber(orientation);
            index_of_nearest_marker = obj.MarkerLayer.GetMarkerImage.GetIndexOfPreviousMarker(current_coordinate, maximum_skip, orientation);
            obj.SliceNumber(orientation) = index_of_nearest_marker;
        end
        
        function GotoNextMarker(obj)
        % Find the image slice containing the next marker
        
            maximum_skip = obj.SliceSkip;
            orientation = obj.Orientation;
            current_coordinate = obj.SliceNumber(orientation);
            index_of_nearest_marker =  obj.MarkerLayer.GetMarkerImage.GetIndexOfNextMarker(current_coordinate, maximum_skip, orientation);            
            obj.SliceNumber(orientation) = index_of_nearest_marker;
        end
        
        function GotoNearestMarker(obj)
        % Find the image slice containing the nearest marker

            orientation = obj.Orientation;
            current_coordinate = obj.SliceNumber(orientation);
            index_of_nearest_marker = obj.MarkerLayer.GetMarkerImage.GetIndexOfNearestMarker(current_coordinate, orientation);
            obj.SliceNumber(orientation) = index_of_nearest_marker;
        end
        
        function GotoFirstMarker(obj)
        % Find the image slice containing the first marker

            orientation = obj.Orientation;
            index_of_nearest_marker = obj.MarkerLayer.GetMarkerImage.GetIndexOfFirstMarker(orientation);
            obj.SliceNumber(orientation) = index_of_nearest_marker;
        end
        
        function GotoLastMarker(obj)
        % Find the image slice containing the last marker

            orientation = obj.Orientation;
            index_of_nearest_marker = obj.MarkerLayer.GetMarkerImage.GetIndexOfLastMarker(orientation);
            obj.SliceNumber(orientation) = index_of_nearest_marker;
        end
    end
    
    methods (Access = protected)
        
        function PostCreation(obj, position, reporting)
            % Called after the component and all its children have been created
            
            obj.ViewerPanelCallback = MimViewerPanelCallback(obj, obj.ViewerPanelMultiView, obj.Tools, obj.DefaultOrientation, obj.Reporting);
        end            

        function input_has_been_processed = Keypressed(obj, click_point, key)
            % Processes keys pressed while mouse is over the viewer window
            
            input_has_been_processed = obj.ShortcutKeys(key);
        end
        
        function input_has_been_processed = Scroll(obj, current_point, scroll_count)
            % Mousewheel cine when the mouse is anywhere in the viewer panel
            
            obj.SliceNumber(obj.Orientation) = obj.SliceNumber(obj.Orientation) + scroll_count;
            input_has_been_processed = true;
        end
        
    end
end