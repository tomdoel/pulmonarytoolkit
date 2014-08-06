classdef PTKImageOverlayAxes < PTKImageAxes
    % PTKImageOverlayAxes. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKImageOverlayAxes is used to build axes containing image, overlay and
    %     quiver overlay image objects
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        
        % Screen components displaying the background and overlay images
        BackgroundScreenImage
        OverlayScreenImage
        QuiverScreenImage
        
    end
    
    methods
        function obj = PTKImageOverlayAxes(parent, reporting)
            obj = obj@PTKImageAxes(parent);
            
            % Add the screen images to the axes
            obj.BackgroundScreenImage = PTKScreenImage(obj);
            obj.AddChild(obj.BackgroundScreenImage, reporting);
            obj.OverlayScreenImage = PTKScreenImage(obj);
            obj.AddChild(obj.OverlayScreenImage, reporting);
            obj.QuiverScreenImage = PTKScreenQuiverImage(obj);
            obj.AddChild(obj.QuiverScreenImage, reporting);
            
        end
        
        function Resize(obj, position)
            Resize@PTKImageAxes(obj, position);
            
            obj.BackgroundScreenImage.Resize(position);
            obj.OverlayScreenImage.Resize(position);
            obj.QuiverScreenImage.Resize(position);
        end
        
        function UpdateAxesAndScreenImages(obj, background_image, overlay_image, quiver_image, orientation)
            if (background_image.ImageExists)
                [x_range, y_range] = obj.UpdateAxes(background_image, orientation);
                
                [dim_x_index, dim_y_index, dim_z_index] = PTKImageCoordinateUtilities.GetXYDimensionIndex(orientation);
                
                % Background image
                obj.BackgroundScreenImage.SetRange(x_range, y_range);
                
                % Overlay image
                overlay_offset_voxels = PTKImageCoordinateUtilities.GetOriginOffsetVoxels(background_image, overlay_image);
                overlay_offset_x_voxels = overlay_offset_voxels(dim_x_index);
                overlay_offset_y_voxels = overlay_offset_voxels(dim_y_index);
                obj.OverlayScreenImage.SetRange(x_range - overlay_offset_x_voxels, y_range - overlay_offset_y_voxels);
                
                % Quiver image
                quiver_offset_voxels = PTKImageCoordinateUtilities.GetOriginOffsetVoxels(background_image, quiver_image);
                quiver_offset_x_voxels = quiver_offset_voxels(dim_x_index);
                quiver_offset_y_voxels = quiver_offset_voxels(dim_y_index);
                obj.QuiverScreenImage.SetRange(x_range - quiver_offset_x_voxels, y_range - quiver_offset_y_voxels);
            end
        end
        
        function DrawBackgroundImage(obj, viewer_panel)
            obj.BackgroundScreenImage.DrawImageSlice(viewer_panel.BackgroundImage, viewer_panel.BackgroundImage, 100*viewer_panel.ShowImage, false, viewer_panel.Window, viewer_panel.Level, viewer_panel.OpaqueColour, viewer_panel.SliceNumber(viewer_panel.Orientation), viewer_panel.Orientation);
        end
        
        function DrawOverlayImage(obj, viewer_panel)
            obj.OverlayScreenImage.DrawImageSlice(viewer_panel.OverlayImage, viewer_panel.BackgroundImage, viewer_panel.OverlayOpacity*viewer_panel.ShowOverlay, viewer_panel.BlackIsTransparent, viewer_panel.Window, viewer_panel.Level, viewer_panel.OpaqueColour, viewer_panel.SliceNumber(viewer_panel.Orientation), viewer_panel.Orientation);
        end

        function DrawQuiverImage(obj, quiver_on, viewer_panel)
            obj.QuiverScreenImage.DrawQuiverSlice(quiver_on, viewer_panel.QuiverImage, viewer_panel.SliceNumber(viewer_panel.Orientation), viewer_panel.Orientation)
        end
        
    end
end