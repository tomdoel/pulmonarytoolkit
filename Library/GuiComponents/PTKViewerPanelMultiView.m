classdef PTKViewerPanelMultiView < PTKMultiPanel
    % PTKViewerPanelMultiView. Contains panels for 2D and 3D views, and allows
    %     switching between them
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (Access = private)        
        CinePanel2D
    end

    events
        MousePositionChanged
    end
    
    methods
        function obj = PTKViewerPanelMultiView(viewer_panel, reporting)
            obj = obj@PTKMultiPanel(viewer_panel, reporting);
            
            obj.CinePanel2D = PTKCinePanel(viewer_panel, obj.Reporting);
            
            obj.AddPanel(obj.CinePanel2D, 'View2D');
            
            % Change in mouse position
            obj.AddEventListener(obj.CinePanel2D, 'MousePositionChanged', @obj.MousePositionChangedCallback);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKMultiPanel(obj, position, reporting);

%             obj.UpdateGui;
            obj.Resize(position);
        end
        
        function Resize(obj, position)
            Resize@PTKMultiPanel(obj, position);
            
            % Position axes and slice slider
            obj.CinePanel2D.Resize(position);
        end
        
        function ZoomTo(obj, i_limits, j_limits, k_limits)
            obj.CinePanel2D.ZoomTo(i_limits, j_limits, k_limits);
        end

        function frame = Capture(obj)
            frame = obj.CinePanel2D.Capture;
        end
        
        function UpdateCursor(obj, hObject, mouse_is_down, keyboard_modifier)
            obj.CinePanel2D.UpdateCursor(hObject, mouse_is_down, keyboard_modifier);
        end
        
        function axes_object = GetAxes(obj)
            axes_object = obj.CinePanel2D.GetAxes;            
        end
        
        function DrawImages(obj, update_background, update_overlay, update_quiver)
            obj.CinePanel2D.DrawImages(update_background, update_overlay, update_quiver);
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