classdef PTKViewer < handle
    % PTKViewer. A standalone image viewer for showing 3D images slice-by-slice
    %
    %     PTKViewer uses PTKViewerPanel to create a visualisation window for the
    %     supplied image, which can be a PTKImage or raw data. If a raw data
    %     matrix is supplied, the type argument can be supplied to ensure the
    %     image is displayed as expected.
    %
    %     Examples
    %     --------
    %
    %         % Displays my_image, where my_image is a 3D image matrix or a PTKImage
    %         PTKViewer(my_image);
    %
    %         % Displays my_image as a greyscale image, where my_image is a 3D image.
    %         % If my_Image is a PTKImage, the type will be ignored
    %         PTKViewer(my_image, PTKImageType.Grayscale);
    %
    %         % Displays my_image as a greyscale image, and overlay_image as an indexed colour image
    %         viewer = PTKViewer(my_image, PTKImageType.Grayscale);
    %         viewer.ViewerPanelHandle.OverlayImage = overlay_image; % Must be a PTKImage
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        FigureHandle
        ViewerPanelHandle
        ImageHandle
    end

    properties (Dependent = true)
        Title
    end

    methods
        function obj = PTKViewer(image, type)
            obj.FigureHandle = figure;
            set(obj.FigureHandle, 'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none');
            obj.ViewerPanelHandle = PTKViewerPanel(obj.FigureHandle);
            if nargin < 1
                image = [];
            end
            if isa(image, 'PTKImage')
                obj.ImageHandle = image;
                if ~isempty(image.Title)
                    obj.Title = image.Title;
                else
                    obj.Title = 'PTKViewer';
                end
            else
                if nargin < 2
                    obj.ImageHandle = PTKImage(image);
                else
                    obj.ImageHandle = PTKImage(image, type);
                end
                obj.Title = 'PTKViewer';
            end
            obj.ViewerPanelHandle.BackgroundImage = obj.ImageHandle;

            % Set custom function for application closing
            set(obj.FigureHandle, 'CloseRequestFcn', @obj.CustomCloseFunction);

        end
        
        function delete(obj)
            delete(obj.ViewerPanelHandle);
            if ishandle(obj.FigureHandle)
                delete(obj.FigureHandle);
            end
        end        
        
        function title = get.Title(obj)
            title = get(obj.FigureHandle, 'Name');
        end
        
        function set.Title(obj, title)
            set(obj.FigureHandle, 'Name', title);
        end

    end

    methods (Access = private)

        function CustomCloseFunction(obj, ~, ~)
            delete(obj);
        end
        
    end
end
