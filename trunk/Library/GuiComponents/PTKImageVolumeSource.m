classdef PTKImageVolumeSource < PTKBaseClass
    % PTKImageVolumeSource. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKImageVolumeSource is used in converting a 3D image volume into
    %     a 2D image slice
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
        function obj = PTKImageVolumeSource(viewer_panel)
            obj = obj@PTKBaseClass;
            obj.ViewerPanel = viewer_panel;
        end
        
        function orientation = GetOrientation(obj)
            orientation = obj.ViewerPanel.Orientation;
        end
        
        function SetSliceNumber(obj, i_num, j_num, k_num)
            obj.ViewerPanel.SliceNumber = [i_num, j_num, k_num];
        end
        
        function SetSliceNumberForOrientation(obj, orientation, slice_number)
            obj.ViewerPanel.SliceNumber(orientation) = slice_number;
        end
        
        function slice_number = GetSliceNumber(obj)
            slice_number = obj.ViewerPanel.SliceNumber;
        end
        
        function slice_number = GetSliceNumberForOrientation(obj, orientation)
            slice_number = obj.ViewerPanel.SliceNumber;
            slice_number = slice_number(orientation);
        end
        
        
        function origin = GetOrigin(obj)
            origin = obj.ViewerPanel.BackgroundImage.Origin;
        end
        
        function image_size = GetImageSize(obj)
            image_size = obj.ViewerPanel.BackgroundImage.ImageSize;
        end
        
        function voxel_size = GetVoxelSize(obj)
            voxel_size = obj.ViewerPanel.BackgroundImage.VoxelSize;
        end
        
        function image_exists = ImageExists(obj)
            image_exists = obj.ViewerPanel.BackgroundImage.ImageExists;
        end
        
        function point_is_in_image = IsPointInImage(obj, global_coords)
            point_is_in_image = obj.ViewerPanel.BackgroundImage.IsPointInImage(global_coords);
        end
    end
end