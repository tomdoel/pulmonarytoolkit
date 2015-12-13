classdef PTKQuiverScreenImageFromVolume < GemScreenQuiverImage
    % PTKQuiverScreenImageFromVolume. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
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
        ViewerPanel
    end
    
    methods
        function obj = PTKQuiverScreenImageFromVolume(parent, image_source, viewer_panel, image_parameters)
            obj = obj@GemScreenQuiverImage(parent, image_source, image_parameters);
            obj.ViewerPanel = viewer_panel;
        end
        
        function DrawImage(obj)
            obj.DrawQuiverSlice(obj.ViewerPanel.ShowOverlay);
        end
            
        function SetRangeWithPositionAdjustment(obj, x_range, y_range)
            [dim_x_index, dim_y_index, dim_z_index] = GemUtilities.GetXYDimensionIndex(obj.ViewerPanel.Orientation);
            
            quiver_offset_voxels = PTKImageCoordinateUtilities.GetOriginOffsetVoxels(obj.ViewerPanel.BackgroundImage, obj.ViewerPanel.QuiverImage);
            quiver_offset_x_voxels = quiver_offset_voxels(dim_x_index);
            quiver_offset_y_voxels = quiver_offset_voxels(dim_y_index);
            obj.SetRange(x_range - quiver_offset_x_voxels, y_range - quiver_offset_y_voxels);
        end
    end
end