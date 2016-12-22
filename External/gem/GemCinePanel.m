classdef GemCinePanel < GemVirtualPanel
    % GemCinePanel  Image axes with scrollbar for displaing a slice of a 3D volume
    %
    %     GemCinePanel contains a 2D image and a slider, which allows the user to
    %     cine through slices of a 3D images
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties (Access = protected)
        Axes
        ImageSource
        ImageParameters
        Slider
    end
    
    events
        MousePositionChanged
    end

    methods
        function obj = GemCinePanel(parent, image_source, image_parameters, image_overlay_axes)
            obj = obj@GemVirtualPanel(parent);

            obj.ImageSource = image_source;
            obj.ImageParameters = image_parameters;
            
            obj.Slider = GemSlider(obj);
            obj.AddChild(obj.Slider);
            
            obj.Axes = image_overlay_axes;
            obj.AddChild(obj.Axes);
            
            obj.AddEventListener(obj.Slider, 'SliderValueChanged', @obj.SliderValueChanged);            
        end

        function Resize(obj, position)
            Resize@GemUserInterfaceObject(obj, position);
            
            % Resize axes
            axis_width = max(1, position(3) - obj.Slider.SliderWidth);
            axes_position = [position(1), position(2), axis_width, position(4)];
            obj.Axes.Resize(axes_position);
            
            % Resize slider
            slider_x = position(1) + axis_width;
            slider_position = [slider_x, position(2) - 1, obj.Slider.SliderWidth, position(4)];
            obj.Slider.Resize(slider_position);            
        end
        
        function SetSliceNumber(obj, slice_number)
            current_slice_value = obj.Slider.SliderValue;
            if (current_slice_value ~= slice_number)
                obj.Slider.SetSliderValue(slice_number);
            end
        end
        
        function SetSliderLimits(obj, min, max)
            obj.Slider.SetSliderLimits(min, max);
        end
        
        function SetSliderSteps(obj, steps)
            obj.Slider.SetSliderSteps(steps);
        end
  
        function EnableSlider(obj, enabled)
            if enabled
                obj.Slider.Enable;
            else
                obj.Slider.Disable;
            end
        end

        function frame = Capture(obj, image_size, orientation)
            drawnow;
            
            origin = [0.5, 0.5, 0.5];
            image_limit = origin + image_size;
            switch orientation
                case GemImageOrientation.XZ
                    xlim_image = [origin(2), image_limit(2)];
                    ylim_image = [origin(3), image_limit(3)];
                case GemImageOrientation.YZ
                    xlim_image = [origin(1), image_limit(1)];
                    ylim_image = [origin(3), image_limit(3)];
                case GemImageOrientation.XY
                    xlim_image = [origin(2), image_limit(2)];
                    ylim_image = [origin(1), image_limit(1)];
            end

            frame = obj.Axes.Capture(xlim_image, ylim_image);
        end

        function ZoomTo(obj, i_limits, j_limits, k_limits)
            % Changes the current axis limits to the specified global coordinates
            % i_limits = [minimum_i, maximum_i] and the same for j, k.

            obj.Axes.ZoomTo(obj, i_limits, j_limits, k_limits);
            
        end
        
        function ClearAxesCache(obj)
            obj.Axes.ClearAxesCache;
        end
            
        function UpdateAxes(obj)
            obj.Axes.UpdateAxes;
        end
        
        function screen_coords = GetScreenCoordinates(obj)
            coords = obj.Axes.GetCurrentPoint;
            if (~isempty(coords))
                i_screen = coords(2,1);
                j_screen = coords(2,2);
                screen_coords = [i_screen, j_screen];
            else
                screen_coords = [0, 0];
            end
        end
        
        function current_point = GetCurrentPoint(obj)
            current_point = obj.Axes.GetCurrentPoint;
        end
       
        function axes_object = GetAxes(obj)
            if isempty(obj.Axes)
                obj.Reporting.Error('GemCinePanel:AxesDoNotExist', 'Axes have not been created');
            end
            axes_object = obj.Axes;
        end
       
        function global_coords = GetImageCoordinates(obj)
            coords = round(obj.GetCurrentPoint);
            if (~isempty(coords))
                orientation = obj.ImageParameters.Orientation;
                i_screen = coords(2,1);
                j_screen = coords(2,2);
                k_screen = obj.ImageParameters.SliceNumber(orientation);
                
                switch orientation
                    case GemImageOrientation.XZ
                        i = k_screen;
                        j = i_screen;
                        k = j_screen;
                    case GemImageOrientation.YZ
                        i = i_screen;
                        j = k_screen;
                        k = j_screen;
                    case GemImageOrientation.XY
                        i = j_screen;
                        j = i_screen;
                        k = k_screen;
                end
            else
                i = 1;
                j = 1;
                k = 1;
            end
            global_coords = obj.ImageSource.Image.LocalToGlobalCoordinates([i, j, k]);
        end        
    end
    
    methods (Access = protected)
        function input_has_been_processed = MouseDown(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is clicked inside the control
                        
            obj.UpdateStatus(true);
            input_has_been_processed = true;            
        end

        function input_has_been_processed = MouseUp(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is released inside the control
            
            obj.UpdateStatus(true);
            input_has_been_processed = true;            
        end
        
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src, eventdata)
            % Mouse has moved over the figure

            obj.UpdateStatus(true);
            input_has_been_processed = true;
        end
        
        function input_has_been_processed = MouseDragged(obj, click_point, selection_type, src, eventdata)
            % Mouse dragged over the figure

            obj.UpdateStatus(true);
            input_has_been_processed = true;
        end
 
        function input_has_been_processed = MouseExit(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse exits a control which previously
            % processed a MouseHasMoved event

            obj.UpdateStatus(false);
            input_has_been_processed = true;
        end        
        
        function UpdateStatus(obj, in_image)
            image_coordinates = obj.GetImageCoordinates;
            notify(obj, 'MousePositionChanged', CoreEventData(GemCoordsInImage(image_coordinates, in_image)));
        end
        
        function SliderValueChanged(obj, ~, ~)
            obj.ImageParameters.SliceNumber(obj.ImageParameters.Orientation) = round(obj.Slider.SliderValue);
        end
    end
end