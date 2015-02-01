classdef PTKScreenImageFromVolume < PTKScreenImage
    % PTKScreenImageFromVolume. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKScreenImageFromVolume holds a volume, and a 2D image object
    %     which shows one slice from the image volume
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        ImageSource
    end
    
    methods
        function obj = PTKScreenImageFromVolume(parent, image_source)
            obj = obj@PTKScreenImage(parent);
            obj.ImageSource = image_source;
        end

        function DrawImageSlice(obj, image_object, background_image, opacity, black_is_transparent, window, level, opaque_colour, slice_number, orientation)
            if ~isempty(image_object)
                if image_object.ImageExists
                    orientation = obj.ImageSource.GetOrientation;
                    image_slice = PTKScreenImageFromVolume.GetImageSlice(background_image, image_object, slice_number, orientation);
                    image_type = image_object.ImageType;
                    
                    if (image_type == PTKImageType.Scaled)
                        limits = image_object.Limits;
                    elseif (image_type == PTKImageType.Colormap)
                        
                        % For unsigned types, we don't need the limits (see GetImage() below)
                        if isa(image_slice, 'uint8') || isa(image_slice, 'uint16')
                            limits = [];
                        else
                            limits = image_object.Limits;
                        end
                    else
                        limits = [];
                    end
                    
                    level_grayscale = image_object.RescaledToGrayscale(level);
                    window_grayscale = window;
                    if isa(image_object, 'PTKDicomImage')
                        if image_object.IsCT && ~isempty(image_object.RescaleSlope)
                            window_grayscale = window_grayscale/image_object.RescaleSlope;
                        end
                    end
                    
                    [rgb_slice, alpha_slice] = PTKScreenImage.GetImage(image_slice, limits, image_type, window_grayscale, level_grayscale, black_is_transparent, image_object.ColorLabelMap);
                    alpha_slice = double(alpha_slice)*opacity/100;
                    
                    % Special code to highlight one colour
                    if ~isempty(opaque_colour)
                        alpha_slice(image_slice == opaque_colour) = 1;
                    end
                    
                    obj.SetImageData(rgb_slice, alpha_slice);
                else
                    obj.ClearImageData;
                end
            end
            
        end
    end
    
    methods (Access = private, Static)
        
        function image_slice = GetImageSlice(background_image, image_object, slice_number, orientation)
            offset_voxels = PTKImageCoordinateUtilities.GetOriginOffsetVoxels(background_image, image_object);
            
            slice_number = slice_number - round(offset_voxels(orientation));
            if (slice_number < 1) || (slice_number > image_object.ImageSize(orientation))
                image_slice = image_object.GetBlankSlice(orientation);
            else
                image_slice = image_object.GetSlice(slice_number, orientation);
            end
            if (orientation ~= PTKImageOrientation.Axial)
                image_slice = image_slice';
            end
        end
        
    end
    
end