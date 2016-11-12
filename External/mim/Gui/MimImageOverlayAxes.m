classdef MimImageOverlayAxes < GemImageAxes
    % MimImageOverlayAxes. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     MimImageOverlayAxes is used to build axes containing image, overlay and
    %     quiver overlay image objects
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        % Screen components displaying the background and overlay images
        BackgroundScreenImage
        OverlayScreenImage
        QuiverScreenImage
        
    end
    
    methods
        function obj = MimImageOverlayAxes(parent, background_image_source, overlay_image_source, quiver_image_source, image_parameters, background_view_parameters, overlay_view_parameters)
            obj = obj@GemImageAxes(parent, background_image_source, image_parameters);
            
            % Add the screen images to the axes
            obj.BackgroundScreenImage = MimImageFromVolume(obj, background_image_source, image_parameters, background_view_parameters, background_image_source);
            obj.AddChild(obj.BackgroundScreenImage);
            obj.OverlayScreenImage = MimImageFromVolume(obj, overlay_image_source, image_parameters, overlay_view_parameters, background_image_source);
            obj.AddChild(obj.OverlayScreenImage);
            obj.QuiverScreenImage = MimQuiverImageFromVolume(obj, quiver_image_source, image_parameters, overlay_view_parameters, background_image_source);
            obj.AddChild(obj.QuiverScreenImage);
        end
        
        function DrawBackgroundImage(obj)
            obj.BackgroundScreenImage.DrawImage;
        end
        
        function DrawOverlayImage(obj)
            obj.OverlayScreenImage.DrawImage;
        end
        
        function DrawQuiverImage(obj)
            obj.QuiverScreenImage.DrawImage;
        end
    end
end