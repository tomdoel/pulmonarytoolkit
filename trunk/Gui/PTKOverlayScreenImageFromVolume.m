classdef PTKOverlayScreenImageFromVolume < PTKScreenImageFromVolume
    % PTKOverlayScreenImageFromVolume. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
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
    end
    
    methods
        function obj = PTKOverlayScreenImageFromVolume(parent, image_source, viewer_panel)
            obj = obj@PTKScreenImageFromVolume(parent, image_source);
            obj.ViewerPanel = viewer_panel;
        end
        
        function DrawImage(obj)
            obj.DrawImageSlice(obj.ViewerPanel.OverlayImage, obj.ViewerPanel.BackgroundImage, obj.ViewerPanel.OverlayOpacity*obj.ViewerPanel.ShowOverlay, obj.ViewerPanel.BlackIsTransparent, obj.ViewerPanel.Window, obj.ViewerPanel.Level, obj.ViewerPanel.OpaqueColour, obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation), obj.ViewerPanel.Orientation);
        end

        function SetRangeWithPositionAdjustment(obj, x_range, y_range)
            [dim_x_index, dim_y_index, dim_z_index] = PTKImageCoordinateUtilities.GetXYDimensionIndex(obj.ViewerPanel.Orientation);
            
            overlay_offset_voxels = PTKImageCoordinateUtilities.GetOriginOffsetVoxels(obj.ViewerPanel.BackgroundImage, obj.ViewerPanel.OverlayImage);
            overlay_offset_x_voxels = overlay_offset_voxels(dim_x_index);
            overlay_offset_y_voxels = overlay_offset_voxels(dim_y_index);
            obj.SetRange(x_range - overlay_offset_x_voxels, y_range - overlay_offset_y_voxels);
        end
    end
end