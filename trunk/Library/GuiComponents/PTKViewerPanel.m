classdef PTKViewerPanel < PTKPanel
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
    

    events
        MarkerPanelSelected      % An event to indicate if the marker control has been selected
        OverlayImageChangedEvent % An event to indicate if the overlay image has changed
    end
    
    properties (SetObservable)
        SelectedControl = 'W/L'  % The currently selected tool
        Orientation = PTKImageOrientation.Coronal  % The currently selected image orientation
        OverlayOpacity = 50    % Sets the opacity percentage of the transparent overlay image
        ShowImage = true       % Sets whether the greyscale image is visible or invisible
        ShowOverlay = true     % Sets whether the transparent overlay image is visible or invisible
        BlackIsTransparent = true  % Sets whether black in the transparent overlay image is transparent or shown as black
        Window = 1600          % The image window (in HU for CT images)
        Level = -600           % The image level (in HU for CT images)
        SliceNumber = [1 1 1]  % The currently shown slice in 3 dimensions
        SliceSkip = 10         % Number of slices skipped when navigating throough images with the space key
        BackgroundImage        % The greyscale image
        OverlayImage           % The colour transparent overlay image
        QuiverImage            % A vector quiver plot showing directions
        OpaqueColour           % If set, then this colour will always be shown at full opacity in the overlay
    end
    
    properties (SetAccess = private)
        Mode = ''       % Specifies the current editing mode
        SubMode = ''    % Specifies the current editing submode
        EditFixedOuterBoundary   % Specifies whether the current edit can modify the segmentation outer boundary
        ControlPanelHeight = 33
    end
    
    properties (Access = private)
        FigureHandle
        ToolCallback
        Tools
        ControlPanel
        ViewerPanelMultiView
        ViewerPanelCallback
    end
    
    methods
        
        function obj = PTKViewerPanel(parent)
            % Creates a PTKViewerPanel
            
            obj = obj@PTKPanel(parent);
            
            % These image objects must be created here, not in the properties section, to
            % prevent Matlab creating a circular dependency (see Matlab solution 1-6K9BQ7)
            obj.BackgroundImage = PTKImage;
            obj.OverlayImage = PTKImage;
            obj.QuiverImage = PTKImage;
            
            % Create the mouse tools
            obj.ToolCallback = PTKToolCallback(obj, obj.Reporting);
            obj.Tools = PTKToolList(obj.ToolCallback, obj);
            
            % Create the coontrol panel
            obj.ControlPanel = PTKViewerPanelToolbar(obj, obj.Tools, obj.Reporting);
            obj.AddChild(obj.ControlPanel, obj.Reporting);

            % Create the renderer object, which handles the image processing in the viewer
            obj.ViewerPanelMultiView = PTKViewerPanelMultiView(obj, obj.ControlPanel, obj.Reporting);
            obj.ToolCallback.SetRenderer(obj.ViewerPanelMultiView);
            obj.AddChild(obj.ViewerPanelMultiView, obj.Reporting);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKPanel(obj, position, reporting);
        
            obj.FigureHandle = obj.Parent.GetContainerHandle;
        end
        
        function Resize(obj, position)
            % Resize the viewer panel and its subcomponents
            
            Resize@PTKPanel(obj, position);
            
            % Position axes and slice slider
            parent_width_pixels = position(3);
            parent_height_pixels = position(4);
            image_width = parent_width_pixels;
            control_panel_height = obj.ControlPanelHeight;
            image_height = max(1, parent_height_pixels - control_panel_height);
            control_panel_position = [1, 1, image_width, control_panel_height];
            image_panel_position = [1, control_panel_height, image_width, image_height];            
            
            % Resize the image and slider
            obj.ViewerPanelMultiView.Resize(image_panel_position);
            
            obj.ViewerPanelMultiView.UpdateAxes;
            
            % Resize the control panel
            obj.ControlPanel.Resize(control_panel_position);
        end
        
        function marker_point_manager = GetMarkerPointManager(obj)
            % Returns a pointer to the MarkerPointManager object
            
            marker_point_manager = obj.Tools.GetMarkerPointManager;
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
            
            frame = obj.ViewerPanelMultiView.Capture;
        end

        function SetControl(obj, tag_value)
            % Changes the active tool, specified by tag string, e.g. 'Cine'
            
            obj.SelectedControl = tag_value;
            
            % Change the cursor
            obj.ViewerPanelMultiView.UpdateCursor(obj.FigureHandle, [], []);
            
            obj.Tools.SetControl(tag_value);
            obj.ControlPanel.SetControl(tag_value);

        end
        
        function SetModes(obj, mode, submode)
            % Changes the active edit mode and submode
            
            obj.Mode = mode;
            obj.SubMode = submode;
            
            % Need to resize the control panel as the number of tools may have changed
            obj.ResizeControlPanel;
            
            if strcmp(mode, PTKModes.EditMode)
                if strcmp(submode, PTKSubModes.ColourRemapEditing)
                    obj.SetControl('Map');
                elseif strcmp(submode, PTKSubModes.EditBoundariesEditing)
                    obj.SetControl('Edit');
                elseif strcmp(submode, PTKSubModes.FixedBoundariesEditing)
                    obj.SetControl('Edit');
                else
                    obj.SetControl('W/L');
                end
            else
                obj.SetControl('W/L');
            end
        end
        
        function renderer = GetRenderer(obj)
            renderer = obj.ViewerPanelMultiView;
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
            else
                % Otherwise allow the control panel and its tools to process shortcut keys
                input_has_been_processed = obj.ControlPanel.ShortcutKeys(key);
            end
        end
        
    end
    
    methods (Access = protected)
        
        function PostCreation(obj, position, reporting)
            % Called after the compent and all its children have been created
            
            obj.ViewerPanelCallback = PTKViewerPanelCallback(obj, obj.ViewerPanelMultiView, obj.Tools, obj.ControlPanel, obj.Reporting);
            obj.UpdateStatus;
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
    
    
    methods (Access = private)
        
        function UpdateStatus(obj)
            global_coords = obj.ViewerPanelMultiView.GetImageCoordinates;
            obj.ControlPanel.UpdateStatus(global_coords);
        end
        
        function ResizeControlPanel(obj)
            control_panel_position = obj.Position;
            control_panel_position(4) = obj.ControlPanelHeight;
            obj.ControlPanel.Resize(control_panel_position);            
        end

    end
end