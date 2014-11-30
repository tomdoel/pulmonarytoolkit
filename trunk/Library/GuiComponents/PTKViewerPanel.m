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
        MouseCursorStatusChanged % An event to indicate if the MouseCursorStatus property has changed
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
        PaintBrushSize = 5     % Size of the paint brush used by the ReplaceColourTool
    end
    
    properties (SetObservable, SetAccess = private)
        WindowLimits           % The limits of the image window (in HU for CT images)  
        LevelLimits            % The limits of the image level (in HU for CT images)  
    end
    
    properties (SetAccess = private)
        Mode = ''       % Specifies the current editing mode
        SubMode = ''    % Specifies the current editing submode
        EditFixedOuterBoundary   % Specifies whether the current edit can modify the segmentation outer boundary
        ControlPanelHeight = 33
        MouseCursorStatus      % A class of type PTKMouseCursorStatus showing data representing the voxel under the cursor
    end
    
    properties (Access = private)
        LevelMin
        LevelMax
        WindowMin
        WindowMax
        
        FigureHandle
        ToolCallback
        Tools
        ControlPanel
        ViewerPanelMultiView
        ViewerPanelCallback
    end
    
    properties
        ShowControlPanel = true
    end
    
    methods
        
        function obj = PTKViewerPanel(parent, show_control_panel)
            % Creates a PTKViewerPanel
            
            obj = obj@PTKPanel(parent);
            
            if nargin > 1
                obj.ShowControlPanel = show_control_panel;
            end
            
            obj.MouseCursorStatus = PTKMouseCursorStatus;
            
            % These image objects must be created here, not in the properties section, to
            % prevent Matlab creating a circular dependency (see Matlab solution 1-6K9BQ7)
            obj.BackgroundImage = PTKImage;
            obj.OverlayImage = PTKImage;
            obj.QuiverImage = PTKImage;
            
            % Create the mouse tools
            obj.ToolCallback = PTKToolCallback(obj, obj.Reporting);
            obj.Tools = PTKToolList(obj.ToolCallback, obj);
            
            % Create the coontrol panel
            if obj.ShowControlPanel
                obj.ControlPanel = PTKViewerPanelToolbar(obj, obj.Tools, obj.Reporting);
                obj.AddChild(obj.ControlPanel, obj.Reporting);
            end

            % Create the renderer object, which handles the image processing in the viewer
            obj.ViewerPanelMultiView = PTKViewerPanelMultiView(obj, obj.Reporting);
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
            
            if obj.ShowControlPanel
                control_panel_height = obj.ControlPanelHeight;
                control_panel_width = image_width;
            else
                control_panel_height = 0;
                control_panel_width = 0;
            end
            
            image_height = max(1, parent_height_pixels - control_panel_height);
            
            control_panel_position = [1, 1, control_panel_width, control_panel_height];
            image_panel_position = [1, 1 + control_panel_height, image_width, image_height];
            
            % Resize the image and slider
            obj.ViewerPanelMultiView.Resize(image_panel_position);
            
            obj.ViewerPanelMultiView.UpdateAxes;
            
            % Resize the control panel
            if obj.ShowControlPanel
                obj.ControlPanel.Resize(control_panel_position);
            end
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
            
            if obj.ShowControlPanel
                obj.ControlPanel.SetControl(tag_value);
            end

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
            else
                input_has_been_processed = obj.Tools.ShortcutKeys(key, obj.SelectedControl);
            end
        end
     
        function [window_min, window_max] = GetWindowLimits(obj)
            % Returns the minimum and maximum values from the window slider
            
            window_min = obj.WindowMin;
            window_max = obj.WindowMax;
        end
        
        function SetWindowLimits(obj, window_min, window_max)
            % Sets the minimum and maximum values for the level slider
            
            obj.WindowLimits = [window_min, window_max];
            
            if obj.ShowControlPanel
                obj.ControlPanel.UpdateWindowLimits;
            end
        end
        
        function SetLevelLimits(obj, level_min, level_max)
            % Sets the minimum and maximum values for the level slider
            
            obj.LevelLimits = [level_min, level_max];

            if obj.ShowControlPanel
                obj.ControlPanel.UpdateLevelLimits;
            end
        end
        
        function ModifyWindowLevelLimits(obj)
            % This function is used to change the max window and min/max level
            % values after the window or level has been changed to a value outside
            % of the limits
            
            changed = false;
            
            if obj.Level > obj.LevelMax
                obj.LevelMax = obj.Level;
                changed = true;
            end
            if obj.Level < obj.LevelMin
                obj.LevelMin = obj.Level;
                changed = true;
            end
            if obj.Window > obj.WindowMax
                obj.WindowMax = obj.Window;
                changed = true;
            end

            if obj.Window < 0
                obj.Window = 0;
                changed = true;
            end

            if obj.ShowControlPanel && changed
                obj.ControlPanel.UpdateLevelLimits;
            end
        end        
        
        function tool = GetCurrentTool(obj, mouse_is_down, keyboard_modifier)
            tool = obj.Tools.GetCurrentTool(mouse_is_down, keyboard_modifier, obj.SelectedControl);
        end
        
    end
    
    methods (Access = protected)
        
        function PostCreation(obj, position, reporting)
            % Called after the compent and all its children have been created
            
            obj.ViewerPanelCallback = PTKViewerPanelCallback(obj, obj.ViewerPanelMultiView, obj.Tools, obj.ControlPanel, obj.Reporting);
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
        
        function ResizeControlPanel(obj)
            control_panel_position = obj.Position;
            control_panel_position(4) = obj.ControlPanelHeight;
            if obj.ShowControlPanel
                obj.ControlPanel.Resize(control_panel_position);
            end
        end

    end
end