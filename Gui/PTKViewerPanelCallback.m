classdef PTKViewerPanelCallback < CoreBaseClass
    % PTKViewerPanelCallback. Class to handle PTKViewerPanel callback events
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        
        % Preferred defalt image orientation
        DefaultOrientation
        
        % Handles for callbacks to udate the GUI
        Tools
        ViewerPanel
        ViewerPanelMultiView
        Reporting
    end
    
    methods
        
        function obj = PTKViewerPanelCallback(viewing_panel, viewing_panel_multi_view, tools, default_orientation, reporting)
            obj.DefaultOrientation = default_orientation;
            obj.Tools = tools;
            obj.ViewerPanel = viewing_panel;
            obj.ViewerPanelMultiView = viewing_panel_multi_view;
            obj.Reporting = reporting;
            
            obj.NewBackgroundImage;
            obj.NewOverlayImage;
            obj.NewQuiverImage;
            
            % Change in mouse position
            obj.AddEventListener(obj.ViewerPanelMultiView, 'MousePositionChanged', @obj.MousePositionChangedCallback);
            
            % Change in orientation requires a redraw of axes
            obj.AddPostSetListener(obj.ViewerPanel, 'Orientation', @obj.OrientationChangedCallback);
            
            % Tool change updates
            obj.AddPostSetListener(obj.ViewerPanel, 'SelectedControl', @obj.SelectedControlChangedCallback);
            
            % Other changes require redraw of gui
            obj.AddPostSetListener(obj.ViewerPanel, 'SliceNumber', @obj.SliceNumberChangedCallback);
            obj.AddPostSetListener(obj.ViewerPanel, 'Level', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(obj.ViewerPanel, 'Window', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(obj.ViewerPanel, 'OverlayOpacity', @obj.OverlayTransparencyChangedCallback);
            obj.AddPostSetListener(obj.ViewerPanel, 'ShowImage', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(obj.ViewerPanel, 'ShowOverlay', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(obj.ViewerPanel, 'BlackIsTransparent', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(obj.ViewerPanel, 'OpaqueColour', @obj.SettingsChangedCallback);
            
            % Listen for new image events
            obj.AddEventListener(obj.ViewerPanel, 'NewBackgroundImage', @obj.NewBackgroundImageCallback);
            obj.AddEventListener(obj.ViewerPanel, 'NewOverlayImage', @obj.NewOverlayImageCallback);
            obj.AddEventListener(obj.ViewerPanel, 'NewQuiverImage', @obj.NewQuiverImageCallback);
            
            % Listen for image change events
            obj.AddEventListener(obj.ViewerPanel, 'BackgroundImageChanged', @obj.BackgroundImageChangedCallback);
            obj.AddEventListener(obj.ViewerPanel, 'OverlayImageChanged', @obj.OverlayImageChangedCallback);
            obj.AddEventListener(obj.ViewerPanel, 'QuiverImageChanged', @obj.QuiverImageChangedCallback);

            % Status update should be done post-creation
            obj.UpdateStatus;
        end
        
    end
    
    methods (Access = private)
        
        function NewBackgroundImageCallback(obj, ~, ~)
            obj.NewBackgroundImage;
        end
        
        function NewOverlayImageCallback(obj, ~, ~)
            obj.NewOverlayImage;
        end
        
        function NewQuiverImageCallback(obj, ~, ~)
            obj.NewQuiverImage;
        end
        
        function NewBackgroundImage(obj)
            obj.ImageChanged;
        end
        
        function NewOverlayImage(obj)
            no_current_image = ~obj.ViewerPanel.BackgroundImage.ImageExists;
            
            % Update the panel
            if no_current_image % We need to set the axes initially, otherwise the overlay will not appear until UpdateAxes is called
                obj.ImageChanged;
            else
                obj.OverlayImageChanged;
            end
        end
        
        function NewQuiverImage(obj)
            no_current_image = ~obj.ViewerPanel.BackgroundImage.ImageExists;
            
            % Update the panel
            if no_current_image % We need to set the axes initially, otherwise the overlay will not appear until UpdateAxes is called
                obj.ImageChanged;
            else
                obj.OverlayImageChanged;
            end
        end
        
        function BackgroundImageChangedCallback(obj, ~, ~)
            % This methods is called when the background image has changed
            
            obj.ImageChanged;
        end

        function OverlayImageChangedCallback(obj, ~, ~)
            % This methods is called when the overlay image has changed
            
            obj.OverlayImageChanged;
        end

        function QuiverImageChangedCallback(obj, ~, ~)
            % This methods is called when the quiver image has changed
            
            obj.OverlayImageChanged;
        end
        
        function OrientationChangedCallback(obj, ~, ~)
            % This methods is called when the orientation has changed
            
            obj.ViewerPanelMultiView.UpdateAxes;
            obj.UpdateGuiForNewOrientation;
            obj.UpdateGui;
            obj.ViewerPanelMultiView.DrawImages(true, true, true);
            obj.UpdateStatus;
            obj.Tools.NewOrientation;
        end
        
        function SliceNumberChangedCallback(obj, ~, ~, ~)
            % This methods is called when the slice number has changed
            
            obj.UpdateGui;
            obj.Tools.NewSlice;
            obj.ViewerPanelMultiView.DrawImages(true, true, true);
            obj.UpdateStatus;
        end
        
        function SelectedControlChangedCallback(obj, ~, ~, ~)
            % Change the cursor
            obj.ViewerPanelMultiView.UpdateCursor(obj.ViewerPanel.GetParentFigure.GetContainerHandle, [], []);
            
            obj.Tools.SetControl(obj.ViewerPanel.SelectedControl);            
        end
        
        function OverlayTransparencyChangedCallback(obj, ~, ~, ~)
            % This methods is called when the overlay opacity value has
            % changed
            
            if ~obj.ViewerPanel.ShowOverlay
                obj.ViewerPanel.ShowOverlay = true;
            end
            obj.SettingsChangedCallback([], [], []);
        end
        
        function SettingsChangedCallback(obj, ~, ~, ~)
            % This method is called when the settings have changed
            
            % If the window or level values have been externally set outside the
            % slider range, then we modify the slider range to accommodate this
            obj.ModifyWindowLevelLimits;
            
            obj.UpdateGui;
            obj.ViewerPanelMultiView.DrawImages(true, true, true);
            obj.UpdateStatus;
        end
        
        function ImageChanged(obj)
            % This function is called when the background image is modified
            
            obj.ViewerPanelMultiView.ClearAxesCache;
            obj.AutoChangeOrientation;
            obj.ViewerPanelMultiView.UpdateAxes;
            obj.UpdateGuiForNewImage;
            obj.UpdateGuiForNewOrientation;
            obj.UpdateGui;
            obj.ViewerPanelMultiView.DrawImages(true, false, false);
            obj.UpdateStatus;
            
            obj.Tools.ImageChanged;
        end
        
        function OverlayImageChanged(obj)
            % This function is called when the overlay image is modified
            
            obj.ViewerPanelMultiView.UpdateAxes;
            obj.ViewerPanelMultiView.DrawImages(false, true, false);
            obj.Tools.OverlayImageChanged;
            
            notify(obj.ViewerPanel, 'OverlayImageChangedEvent');
        end
        
        function AutoChangeOrientation(obj)
            orientation = obj.ViewerPanel.BackgroundImage.Find2DOrientation;
            if ~isempty(orientation)
                obj.ViewerPanel.Orientation = orientation;
            end
        end
        
        function UpdateGui(obj)
            main_image = obj.ViewerPanel.BackgroundImage;
            
            if ~isempty(main_image) && main_image.ImageExists
                image_size = main_image.ImageSize;
                if obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation) > image_size(obj.ViewerPanel.Orientation)
                    obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation) = image_size(obj.ViewerPanel.Orientation);
                end
                if obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation) < 1
                    obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation) = 1;
                end
                obj.ViewerPanelMultiView.SetSliceNumber(obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation));
            end
        end
        
        function UpdateGuiForNewImage(obj)
            main_image = obj.ViewerPanel.BackgroundImage;
            if ~isempty(main_image) && main_image.ImageExists
                
                obj.AutoOrientationAndWL(main_image);

                limits = main_image.Limits;
                limits_hu = main_image.GrayscaleToRescaled(limits);
                if ~isempty(limits_hu)
                    limits = limits_hu;
                end

                obj.ViewerPanel.SetWindowLimits(0, max(1, 3*(limits(2) - limits(1))));
                if obj.ViewerPanel.Window < 0
                    obj.ViewerPanel.Window = 0;
                end
                if obj.ViewerPanel.Window > max(1, limits(2) - limits(1))
                    obj.ViewerPanel.Window = max(1, limits(2) - limits(1));
                end
                
                obj.ViewerPanel.SetLevelLimits(limits(1), max(limits(1)+1, limits(2)));
                
                if obj.ViewerPanel.Level < limits(1)
                    obj.ViewerPanel.Level = limits(1);
                end
                if obj.ViewerPanel.Level > limits(2)
                    obj.ViewerPanel.Level = limits(2);
                end
            end
        end
        
        function UpdateGuiForNewOrientation(obj)
            main_image = obj.ViewerPanel.BackgroundImage;
            if ~isempty(main_image) && main_image.ImageExists
                
                image_size = main_image.ImageSize;
                slider_max =  max(2, image_size(obj.ViewerPanel.Orientation));
                slider_min = 1;
                if obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation) > image_size(obj.ViewerPanel.Orientation)
                    obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation) = image_size(obj.ViewerPanel.Orientation);
                end
                if obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation) < 1
                    obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation) = 1;
                end

                obj.ViewerPanelMultiView.SetSliceNumber(obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation));
                obj.ViewerPanelMultiView.SetSliderLimits(slider_min, slider_max);
                obj.ViewerPanelMultiView.SetSliderSteps([1/(slider_max - slider_min), 10/(slider_max-slider_min)]);
                obj.ViewerPanelMultiView.EnableSlider(obj.ViewerPanel.BackgroundImage.ImageSize(obj.ViewerPanel.Orientation) > 1);
            else
                obj.ViewerPanelMultiView.EnableSlider(false);
            end
        end
        
        function AutoOrientationAndWL(obj, new_image)
            obj.ViewerPanel.Orientation = PTKImageUtilities.GetPreferredOrientation(new_image, obj.DefaultOrientation);
            
            if isa(new_image, 'PTKDicomImage') && new_image.IsCT
                obj.ViewerPanel.Window = 1600;
                obj.ViewerPanel.Level = -600;
            else
                start_quarter = max(1, round(new_image.ImageSize/4));
                end_quarter = max(1, round(3*new_image.ImageSize/4));
                image_central = new_image.RawImage(start_quarter(1):end_quarter(1),start_quarter(2):end_quarter(2),start_quarter(3):end_quarter(3));
                mean_value = round(mean(image_central(:)));
                obj.ViewerPanel.Window = mean_value*4;
                obj.ViewerPanel.Level = mean_value*2;
            end
        end

        function MousePositionChangedCallback(obj, src, image_coordinates, ~)
            obj.UpdateStatusWithCoords(image_coordinates.Data.Coords, image_coordinates.Data.InImage);
        end
        
        function UpdateStatus(obj)
            global_coords = obj.ViewerPanelMultiView.GetImageCoordinates;
            obj.UpdateStatusWithCoords(global_coords, true);
        end
        
        function UpdateStatusWithCoords(obj, global_coords, in_image)
            
            main_image = obj.ViewerPanel.BackgroundImage;
            overlay_image = obj.ViewerPanel.OverlayImage;
            
            % Whether the cursor is within the volume of the image (whether
            % or not this part of the image is visible)
            image_exists = ~(isempty(main_image) || ~main_image.ImageExists);
            
            
            if image_exists
                if main_image.IsPointInImage(global_coords) && in_image
                    voxel_value = main_image.GetVoxel(global_coords);
                    [rescale_value, rescale_units] = main_image.GetRescaledValue(global_coords);
                    
                    if isempty(overlay_image) || ~overlay_image.ImageExists || ~overlay_image.IsPointInImage(global_coords);
                        overlay_value = [];
                    else
                        overlay_value = overlay_image.GetVoxel(global_coords);
                    end
                    
                else
                    voxel_value = [];
                    overlay_value = [];
                    rescale_value = [];
                    rescale_units = [];
                end
            else
                voxel_value = [];
                overlay_value = [];
                rescale_value = [];
                rescale_units = [];
            end
            
            cursor_status = obj.ViewerPanel.MouseCursorStatus;
            
            % Cursor status is a handle object so we can modify the instance
            cursor_status.GlobalCoordX = global_coords(1);
            cursor_status.GlobalCoordY = global_coords(2);
            cursor_status.GlobalCoordZ = global_coords(3);
            cursor_status.ImageExists = image_exists;
            cursor_status.ImageValue = voxel_value;
            cursor_status.OverlayValue = overlay_value;
            cursor_status.RescaledValue = rescale_value;
            obj.ViewerPanel.MouseCursorStatus.RescaleUnits = rescale_units;
            
            notify(obj.ViewerPanel, 'MouseCursorStatusChanged');
        end
        
        function ModifyWindowLevelLimits(obj)
            % This function is used to change the max window and min/max level
            % values after the window or level has been changed to a value outside
            % of the limits            
            level_limits = obj.ViewerPanel.LevelLimits;
            window_limits = obj.ViewerPanel.WindowLimits;
            window_limits_changed = false;
            level_limits_changed = false;
            
            if ~isempty(level_limits) && ~isempty(window_limits)
                level_min = level_limits(1);
                level_max = level_limits(2);
                window_min = window_limits(1);
                window_max = window_limits(2);
                
                
                if obj.ViewerPanel.Level > level_max
                    level_max = obj.ViewerPanel.Level;
                    level_limits_changed = true;
                end
                if obj.ViewerPanel.Level < level_min
                    level_min = obj.ViewerPanel.Level;
                    level_limits_changed = true;
                end
                if obj.ViewerPanel.Window > window_max
                    window_max = obj.ViewerPanel.Window;
                    window_limits_changed = true;
                end                
                
                if obj.ViewerPanel.Window < 0
                    obj.ViewerPanel.Window = 0;
                    if window_min > 0
                        window_min = 0;
                        window_limits_changed = true;
                    end
                else
                    if obj.ViewerPanel.Window < window_min
                        window_min = obj.ViewerPanel.Window;
                        window_limits_changed = true;
                    end
                end
            end

            if level_limits_changed
                obj.ViewerPanel.SetLevelLimits(level_min, level_max);
            end
            
            if window_limits_changed
                obj.ViewerPanel.SetWindowLimits(window_min, window_max);
            end
        end
    end
end