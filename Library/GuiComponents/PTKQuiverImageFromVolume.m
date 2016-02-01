classdef PTKQuiverImageFromVolume < GemQuiverImage
    % PTKQuiverImageFromVolume. Part of the gui for the Pulmonary Toolkit.
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
        DisplayParameters
        ImageParameters
        ImageSource
        ReferenceImageSource % Used for fusing two images to adjust the positioning of an image
    end
    
    methods
        function obj = PTKQuiverImageFromVolume(parent, image_source, image_parameters, display_parameters, reference_image_source)
            obj = obj@GemQuiverImage(parent, image_source, image_parameters);
            obj.ImageSource = image_source;
            obj.ImageParameters = image_parameters;
            obj.DisplayParameters = display_parameters;
            obj.ReferenceImageSource = reference_image_source;
        end
        
        function DrawImage(obj)
            obj.DrawQuiverSlice(obj.DisplayParameters.ShowImage);
        end
            
        function SetRangeWithPositionAdjustment(obj, x_range, y_range)
            [dim_x_index, dim_y_index, dim_z_index] = GemUtilities.GetXYDimensionIndex(obj.ImageParameters.Orientation);
            
            quiver_offset_voxels = PTKImageCoordinateUtilities.GetOriginOffsetVoxels(obj.ReferenceImageSource.Image, obj.ImageSource.Image);
            quiver_offset_x_voxels = quiver_offset_voxels(dim_x_index);
            quiver_offset_y_voxels = quiver_offset_voxels(dim_y_index);
            obj.SetRange(x_range - quiver_offset_x_voxels, y_range - quiver_offset_y_voxels);
        end
    end
end