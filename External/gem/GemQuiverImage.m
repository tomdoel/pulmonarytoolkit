classdef GemQuiverImage < GemImage
    % GemQuiverImage. GEM class for displaying a quiver image object
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        UData
        VData
        ImageParameters
        ImageSource
    end
    
    methods
        
        function obj = GemQuiverImage(parent, image_source, image_parameters)
            obj = obj@GemImage(parent);
            obj.ImageParameters = image_parameters;
            obj.ImageSource = image_source;
        end
        
        function CreateGuiComponent(obj, position)
            obj.GraphicalComponentHandle = quiver([], [], [], [], 'Parent', obj.Parent.GetContainerHandle, 'Color', 'red');
            if ~isempty(obj.XData)
                set(obj.GraphicalComponentHandle, 'XData', obj.XData, 'YData', obj.YData);
            end
            if ~isempty(obj.UData)
                set(obj.GraphicalComponentHandle, 'UData', obj.UData, 'VData', obj.VData, 'Visible', 'on');
            end
        end
        
        function SetQuiverData(obj, u_data, v_data)
            obj.UData = u_data;
            obj.VData = v_data;
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                set(obj.GraphicalComponentHandle, 'UData', obj.UData, 'VData', obj.VData, 'Visible', 'on');
            end
        end
        
        function ClearQuiverData(obj)
            obj.UData = [];
            obj.VData = [];
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                set(obj.GraphicalComponentHandle, 'UData', [], 'VData', [], 'Visible', 'off');
            end
        end
        
        function DrawQuiverSlice(obj, quiver_on)
            quiver_image_object = obj.ImageSource.Image;
            orientation = obj.ImageParameters.Orientation;
            slice_number = obj.ImageParameters.SliceNumber(orientation);
            if ~isempty(quiver_image_object) && quiver_image_object.ImageExists
                quiver_screen_image = obj;
                if quiver_image_object.ImageExists
                    qs = obj.GetQuiverSlice(quiver_image_object, slice_number, orientation);
                    
                    image_size = quiver_image_object.ImageSize;
                    
                    switch orientation
                        case GemImageOrientation.XZ
                            xy = [2 3];
                        case GemImageOrientation.YZ
                            xy = [1 3];
                        case GemImageOrientation.XY
                            xy = [2 1];
                    end
                    x_range = 1 : image_size(xy(1));
                    y_range = 1 : image_size(xy(2));
                    
                    quiver_screen_image.SetRange(x_range, y_range);
                    if quiver_on
                        quiver_screen_image.SetQuiverData(qs(:, :, xy(1)), qs(:, :, xy(2)));
                    else
                        quiver_screen_image.ClearQuiverData;
                    end
                    
                else
                    quiver_screen_image.ClearQuiverData;
                end
            end
        end
        
    end
    
    methods (Access = private, Static)
        
        function slice = GetQuiverSlice(image_object, slice_number, orientation)
            switch orientation
                case GemImageOrientation.XZ
                    slice = squeeze(image_object.RawImage(slice_number, :, :, :));
                case GemImageOrientation.YZ
                    slice = squeeze(image_object.RawImage(:, slice_number, :, :));
                case GemImageOrientation.XY
                    slice = squeeze(image_object.RawImage(:, :, slice_number, :));
                otherwise
                    error('Unsupported dimension');
            end
            if (orientation ~= GemImageOrientation.XY)
                slice = permute(slice, [2 1 3]);
            end
        end
        
    end
    
end