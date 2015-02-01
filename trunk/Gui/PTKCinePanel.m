classdef PTKCinePanel < PTKVirtualPanel
    % PTKCinePanel.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKCinePanel contains a 2D image and a slider, which allows the user to
    %     cine through slices of a 3D images
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties (Access = protected)
        Axes
        ImageSource
        Slider
    end
    
    methods
        function obj = PTKCinePanel(parent, image_source, image_overlay_axes, reporting)
            obj = obj@PTKVirtualPanel(parent, reporting);

            obj.ImageSource = image_source;
            
            obj.Slider = PTKSlider(obj);
            obj.AddChild(obj.Slider, obj.Reporting);
            
            obj.Axes = image_overlay_axes;
            obj.AddChild(obj.Axes, obj.Reporting);
            
            obj.AddEventListener(obj.Slider, 'SliderValueChanged', @obj.SliderValueChanged);            
        end

        function Resize(obj, position)
            Resize@PTKUserInterfaceObject(obj, position);
            
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
                obj.Slider.Enable(obj.Reporting);
            else
                obj.Slider.Disable;
            end
        end

        function frame = Capture(obj, image_size, orientation)
            drawnow;
            
            origin = [0.5, 0.5, 0.5];
            image_limit = origin + image_size;
            switch orientation
                case PTKImageOrientation.Coronal
                    xlim_image = [origin(2), image_limit(2)];
                    ylim_image = [origin(3), image_limit(3)];
                case PTKImageOrientation.Sagittal
                    xlim_image = [origin(1), image_limit(1)];
                    ylim_image = [origin(3), image_limit(3)];
                case PTKImageOrientation.Axial
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
                obj.Reporting.Error('PTKCinePanel:AxesDoNotExist', 'Axes have not been created');
            end
            axes_object = obj.Axes;
        end
       
    end
    
    methods (Access = protected)
        function SliderValueChanged(obj, ~, ~)
        end
    end
end