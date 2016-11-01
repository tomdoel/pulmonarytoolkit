classdef PTKViewerPanelMultiView < GemMultiPanel
    % PTKViewerPanelMultiView. Contains panels for 2D and 3D views, and allows
    %     switching between them
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
        CinePanel2D
        ImageOverlayAxes
    end

    events
        MousePositionChanged
    end
    
    methods
        function obj = PTKViewerPanelMultiView(viewer_panel, background_image_source, overlay_image_source, quiver_image_source, image_parameters, background_view_parameters, overlay_view_parameters)
            obj = obj@GemMultiPanel(viewer_panel);
            
            obj.ImageOverlayAxes = PTKImageOverlayAxes(obj, background_image_source, overlay_image_source, quiver_image_source, image_parameters, background_view_parameters, overlay_view_parameters);

            obj.CinePanel2D = PTKCinePanelWithTools(obj, obj.ImageOverlayAxes, viewer_panel, background_image_source, image_parameters);
            obj.AddPanel(obj.CinePanel2D, 'View2D');
            
            % Change in mouse position
            obj.AddEventListener(obj.CinePanel2D, 'MousePositionChanged', @obj.MousePositionChangedCallback);
        end
        
        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemMultiPanel(obj, position);

%             obj.UpdateGui;
            obj.Resize(position);
        end
        
        function Resize(obj, position)
            Resize@GemMultiPanel(obj, position);
            
            % Position axes and slice slider
            obj.CinePanel2D.Resize(obj.InnerPosition);
            obj.UpdateAxes;
        end
        
        function ZoomTo(obj, i_limits, j_limits, k_limits)
            obj.CinePanel2D.ZoomTo(i_limits, j_limits, k_limits);
        end

        function frame = Capture(obj, image_size, orientation)
            frame = obj.CinePanel2D.Capture(image_size, orientation);
        end
        
        function UpdateCursor(obj, hObject, mouse_is_down, keyboard_modifier)
            obj.CinePanel2D.UpdateCursor(hObject, mouse_is_down, keyboard_modifier);
        end
        
        function axes_object = GetAxes(obj)
            axes_object = obj.CinePanel2D.GetAxes;            
        end
        
        function DrawImages(obj, update_background, update_overlay, update_quiver)
            if update_background
                obj.ImageOverlayAxes.DrawBackgroundImage;
            end
            if update_overlay
                obj.ImageOverlayAxes.DrawOverlayImage;
            end
            if update_quiver
                obj.ImageOverlayAxes.DrawQuiverImage;
            end
        end
        
        function SetSliceNumber(obj, slice_number)
            obj.CinePanel2D.SetSliceNumber(slice_number);
        end
        
        function SetSliderLimits(obj, min, max)
            obj.CinePanel2D.SetSliderLimits(min, max);
        end
        
        function SetSliderSteps(obj, steps)
            obj.CinePanel2D.SetSliderSteps(steps);
        end
        
        function EnableSlider(obj, enabled)
            obj.CinePanel2D.EnableSlider(enabled);
        end
          
        function UpdateAxes(obj)
            obj.CinePanel2D.UpdateAxes;
        end
        
        function ClearAxesCache(obj)
            obj.CinePanel2D.ClearAxesCache;
        end
        
        function global_coords = GetImageCoordinates(obj)
            global_coords = obj.CinePanel2D.GetImageCoordinates;
        end

        function MousePositionChangedCallback(obj, ~, image_coordinates, ~)
            notify(obj, 'MousePositionChanged', image_coordinates);
        end
    end    
end