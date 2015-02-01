classdef PTKScreenQuiverImage < PTKScreenImage
    % PTKScreenQuiverImage. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKScreenQuiverImage holds a quiver image object
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        UData
        VData
    end
    
    methods
        
        function obj = PTKScreenQuiverImage(parent, image_source)
            obj = obj@PTKScreenImage(parent);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            obj.GraphicalComponentHandle = quiver([], [], [], [], 'Parent', obj.Parent.GetContainerHandle(reporting), 'Color', 'red');
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
        
        function DrawQuiverSlice(obj, quiver_on, quiver_image_object, slice_number, orientation)
            if ~isempty(quiver_image_object) && quiver_image_object.ImageExists
                quiver_screen_image = obj;
                if quiver_image_object.ImageExists
                    qs = obj.GetQuiverSlice(quiver_image_object, slice_number, orientation);
                    
                    image_size = quiver_image_object.ImageSize;
                    
                    switch orientation
                        case PTKImageOrientation.Coronal
                            xy = [2 3];
                        case PTKImageOrientation.Sagittal
                            xy = [1 3];
                        case PTKImageOrientation.Axial
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
                case PTKImageOrientation.Coronal
                    slice = squeeze(image_object.RawImage(slice_number, :, :, :));
                case PTKImageOrientation.Sagittal
                    slice = squeeze(image_object.RawImage(:, slice_number, :, :));
                case PTKImageOrientation.Axial
                    slice = squeeze(image_object.RawImage(:, :, slice_number, :));
                otherwise
                    error('Unsupported dimension');
            end
            if (orientation ~= PTKImageOrientation.Axial)
                slice = permute(slice, [2 1 3]);
            end
        end
        
    end
    
end