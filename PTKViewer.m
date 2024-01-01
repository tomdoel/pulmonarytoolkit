classdef PTKViewer < GemFigure
    % PTKViewer. A standalone image viewer for showing 3D images slice-by-slice
    %
    %     PTKViewer uses MimViewerPanel to create a visualisation window for the
    %     supplied image, which can be a PTKImage or raw data. If a raw data
    %     matrix is supplied, the type argument can be supplied to ensure the
    %     image is displayed as expected.
    %
    %     Example:
    %         obj = PTKViewer;
    %         obj = PTKViewer(image);
    %         obj = PTKViewer(image, image_type);
    %         obj = PTKViewer(image, image_type, reporting);
    %         obj = PTKViewer(image, overlay_image);
    %         obj = PTKViewer(image, overlay_image, reporting);
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
    %         % Displays my_image in the background with overlay_image as an overlay
    %         viewer = PTKViewer(my_image, overlay_image);
    %
    %         % Displays my_image as a greyscale image, and overlay_image as an indexed colour image
    %         viewer = PTKViewer(my_image, PTKImageType.Grayscale);
    %         viewer.ViewerPanelHandle.OverlayImage = overlay_image; % Must be a PTKImage
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ViewerPanelHandle
    end
    
    properties (SetAccess = private)
        Image
        Overlay
    end

    methods
        function obj = PTKViewer(image, overlay_or_type, reporting)
            
            
            if nargin < 1
                image = [];
            end
            
            % The second argument can be the type of the image, or an overlay image
            if nargin < 2
                overlay = [];
                type = [];
            else
                if isa(overlay_or_type, 'PTKImageType')
                    overlay = [];
                    type = overlay_or_type;
                elseif isa(overlay_or_type, 'PTKImage')
                    overlay = overlay_or_type;
                    type = [];
                end
            end
            
            if nargin < 3
                reporting = CoreReportingDefault();
            end
            
            title = 'PTK Viewer';
            
            if isa(image, 'PTKImage')
                image_handle = image;
                if ~isempty(image.Title)
                    title = image.Title;
                end
            else
                if isempty(type)
                    image_handle = PTKImage(image);
                else
                    image_handle = PTKImage(image, type);
                end
            end

            if isa(overlay, 'PTKImage')
                overlay_handle = overlay;
                if isempty(title) && ~isempty(image.Title)
                    title = image.Title;
                end
            else
                overlay_handle = PTKImage(overlay);
            end
            
            if isempty(title)
                title = 'PTK Viewer';
            end
            
            % Call the base class to initialise the hidden window
            obj = obj@GemFigure(title, [], reporting);

            obj.ViewerPanelHandle = MimViewerPanelWithControlPanel(obj);
            obj.AddChild(obj.ViewerPanelHandle);
            
            obj.Image = image_handle;
            obj.Overlay = overlay_handle;
            
            obj.Resize([100 50 700 600]);
            
            % Create the figure
            obj.Show;
            
        end
        
        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemFigure(obj, position);
            
            obj.ViewerPanelHandle.BackgroundImage = obj.Image;               
            obj.ViewerPanelHandle.OverlayImage = obj.Overlay;
            obj.ViewerPanelHandle.SliceNumber = max(1, round(obj.Image.ImageSize/2));
        end
        
        function Resize(obj, position)
            Resize@GemFigure(obj, position);
            
            parent_width_pixels = max(1, position(3));
            parent_height_pixels = max(1, position(4));
            panel_position = [1 1 parent_width_pixels parent_height_pixels];
            obj.ViewerPanelHandle.Resize(panel_position);
        end
    end
end
