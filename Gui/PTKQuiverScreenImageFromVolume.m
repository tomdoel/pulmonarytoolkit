classdef PTKQuiverScreenImageFromVolume < PTKScreenQuiverImage
    % PTKQuiverScreenImageFromVolume. Part of the gui for the Pulmonary Toolkit.
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
        function obj = PTKQuiverScreenImageFromVolume(parent, image_source, viewer_panel)
            obj = obj@PTKScreenQuiverImage(parent, image_source);
            obj.ViewerPanel = viewer_panel;
        end
        
        function DrawImage(obj)
            obj.DrawQuiverSlice(obj.ViewerPanel.ShowOverlay, obj.ViewerPanel.QuiverImage, obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation), obj.ViewerPanel.Orientation);
        end
            
        function SetRangeWithPositionAdjustment(obj, x_range, y_range)
            [dim_x_index, dim_y_index, dim_z_index] = PTKImageCoordinateUtilities.GetXYDimensionIndex(obj.ViewerPanel.Orientation);
            
            quiver_offset_voxels = PTKImageCoordinateUtilities.GetOriginOffsetVoxels(obj.ViewerPanel.BackgroundImage, obj.ViewerPanel.QuiverImage);
            quiver_offset_x_voxels = quiver_offset_voxels(dim_x_index);
            quiver_offset_y_voxels = quiver_offset_voxels(dim_y_index);
            obj.SetRange(x_range - quiver_offset_x_voxels, y_range - quiver_offset_y_voxels);
        end
    end
end