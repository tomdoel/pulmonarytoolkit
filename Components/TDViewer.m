classdef TDViewer < handle
    % TDViewer. A standalone image viewer for showing 3D images slice-by-slice
    %
    %     TDViewer uses TDViewerPanel to create a visualisation window for the
    %     supplied image, which can be a TDImage or raw data. If a raw data
    %     matrix is supplied, the type argument can be supplied to ensure the
    %     image is displayed as expected.
    %
    %     Examples
    %     --------
    %
    %         % Displays my_image, where my_image is a 3D image matrix or a TDImage
    %         TDViewer(my_image);
    %
    %         % Displays my_image as a greyscale image, where my_image is a 3D image.
    %         % If my_Image is a TDImage, the type will be ignored
    %         TDViewer(my_image, TDImageType.Grayscale);
    %
    %         % Displays my_image as a greyscale image, and overlay_image as an indexed colour image
    %         viewer = TDViewer(my_image, TDImageType.Grayscale);
    %         viewer.ViewerPanelHandle.OverlayImage = overlay_image; % Must be a TDImage
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
        function obj = TDViewer(image, type)
            obj.FigureHandle = figure;
            set(obj.FigureHandle, 'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none');
            obj.ViewerPanelHandle = TDViewerPanel(obj.FigureHandle);
            if nargin < 1
                image = [];
            end
            if isa(image, 'TDImage')
                obj.ImageHandle = image;
                if ~isempty(image.Title)
                    obj.Title = image.Title;
                else
                    obj.Title = 'TDViewer';
                end
            else
                if nargin < 2
                    obj.ImageHandle = TDImage(image);
                else
                    obj.ImageHandle = TDImage(image, type);
                end
                obj.Title = 'TDViewer';
            end
            obj.ViewerPanelHandle.BackgroundImage = obj.ImageHandle;

            % Set custom function for application closing
            set(obj.FigureHandle, 'CloseRequestFcn', @obj.CustomCloseFunction);

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
            delete(obj.FigureHandle);
            delete(obj.ViewerPanelHandle);
        end
    end
end
