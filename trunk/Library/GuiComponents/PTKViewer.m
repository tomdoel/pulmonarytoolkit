classdef PTKViewer < PTKFigure
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
        ViewerPanelHandle
    end

    methods
        function obj = PTKViewer(image, type, reporting)
            if nargin < 3
                reporting = PTKReportingDefault;
            end
            
            if nargin < 1
                image = [];
            end
            if isa(image, 'PTKImage')
                image_handle = image;
                if ~isempty(image.Title)
                    title = image.Title;
                else
                    title = 'PTKViewer';
                end
            else
                if nargin < 2
                    image_handle = PTKImage(image);
                else
                    image_handle = PTKImage(image, type);
                end
                title = 'PTKViewer';
            end
            
            % Call the base class to initialise the hidden window
            obj = obj@PTKFigure(title, [], reporting);

            % Set the initial size
            obj.Resize([100 50 700 600]);
            
            % Create the figure
            obj.Show(reporting);
            
            obj.ViewerPanelHandle = PTKViewerPanel(obj.GraphicalComponentHandle);            
            obj.ViewerPanelHandle.BackgroundImage = image_handle;            
        end
        
        function delete(obj)
            delete(obj.ViewerPanelHandle);
        end

    end
end
