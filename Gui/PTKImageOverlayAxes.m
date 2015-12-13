classdef PTKImageOverlayAxes < GemImageAxes
    % PTKImageOverlayAxes. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKImageOverlayAxes is used to build axes containing image, overlay and
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
        function obj = PTKImageOverlayAxes(parent, image_source_old, background_image_source, overlay_image_source, quiver_image_source, viewer_panel, image_parameters)
            obj = obj@GemImageAxes(parent, image_source_old);
            
            % Add the screen images to the axes
            obj.BackgroundScreenImage = PTKBackgroundScreenImageFromVolume(obj, background_image_source, viewer_panel, image_parameters);
            obj.AddChild(obj.BackgroundScreenImage);
            obj.OverlayScreenImage = PTKOverlayScreenImageFromVolume(obj, overlay_image_source, viewer_panel, image_parameters);
            obj.AddChild(obj.OverlayScreenImage);
            obj.QuiverScreenImage = PTKQuiverScreenImageFromVolume(obj, quiver_image_source, viewer_panel, image_parameters);
            obj.AddChild(obj.QuiverScreenImage);
        end
        
        function Resize(obj, position)
            Resize@GemImageAxes(obj, position);
            
            obj.BackgroundScreenImage.Resize(position);
            obj.OverlayScreenImage.Resize(position);
            obj.QuiverScreenImage.Resize(position);
        end
        
        function [x_range, y_range] = UpdateAxes(obj)
            [x_range, y_range] = UpdateAxes@GemImageAxes(obj);
            
            if (obj.ImageSource.ImageExists)
                % Background image
                obj.BackgroundScreenImage.SetRangeWithPositionAdjustment(x_range, y_range);
                
                % Overlay image
                obj.BackgroundScreenImage.SetRangeWithPositionAdjustment(x_range, y_range);
                
                % Quiver image
                obj.QuiverScreenImage.SetRangeWithPositionAdjustment(x_range, y_range);
            end
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