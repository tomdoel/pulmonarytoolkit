classdef MimQuiverImageFromVolume < GemQuiverImage
    % MimQuiverImageFromVolume. Part of the gui for the Pulmonary Toolkit.
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
        
        PendingUpdate = false        
    end
    
    methods
        function obj = MimQuiverImageFromVolume(parent, image_source, image_parameters, display_parameters, reference_image_source)
            obj = obj@GemQuiverImage(parent, image_source, image_parameters);
            obj.ImageSource = image_source;
            obj.ImageParameters = image_parameters;
            obj.DisplayParameters = display_parameters;
            obj.ReferenceImageSource = reference_image_source;
            
            obj.AddPostSetListener(image_parameters, 'Orientation', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(image_parameters, 'SliceNumber', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(display_parameters, 'Level', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(display_parameters, 'Window', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(display_parameters, 'ShowImage', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(display_parameters, 'Opacity', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(display_parameters, 'BlackIsTransparent', @obj.SettingsChangedCallback);
            obj.AddPostSetListener(display_parameters, 'OpaqueColour', @obj.SettingsChangedCallback);
            obj.AddEventListener(image_source, 'NewImage', @obj.SettingsChangedCallback);
            obj.AddEventListener(image_source, 'ImageModified', @obj.SettingsChangedCallback);
            
            obj.AddPostSetListener(image_parameters, 'UpdateLock', @obj.UpdateLockChangedCallback);            
        end
        

        function SettingsChangedCallback(obj, ~, ~, ~)
            if obj.ImageParameters.UpdateLock
                obj.PendingUpdate = true;
            else
                obj.DrawImage;
            end
        end

        function UpdateLockChangedCallback(obj, ~, ~, ~)
            if obj.PendingUpdate && ~obj.ImageParameters.UpdateLock
                obj.DrawImage;
            end            
        end
        
        function DrawImage(obj)
            obj.DrawQuiverSlice(obj.DisplayParameters.ShowImage);
        end
            
        function SetRange(obj, x_range, y_range)
            [dim_x_index, dim_y_index, dim_z_index] = GemUtilities.GetXYDimensionIndex(obj.ImageParameters.Orientation);
            
            quiver_offset_voxels = MimImageCoordinateUtilities.GetOriginOffsetVoxels(obj.ReferenceImageSource.Image, obj.ImageSource.Image);
            quiver_offset_x_voxels = quiver_offset_voxels(dim_x_index);
            quiver_offset_y_voxels = quiver_offset_voxels(dim_y_index);
            SetRange@GemImage(obj, x_range - quiver_offset_x_voxels, y_range - quiver_offset_y_voxels);            
        end
    end
end