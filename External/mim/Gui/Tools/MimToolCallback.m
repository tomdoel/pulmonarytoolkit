classdef MimToolCallback < handle
    % MimToolCallback. 
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        Axes
        Axes3d
        ImageDisplayParameters
        Reporting
        ViewerPanel
    end
    
    methods
        
        function obj = MimToolCallback(viewing_panel, image_display_parameters, axes, axes_3d, reporting)
            obj.ImageDisplayParameters = image_display_parameters;
            obj.ViewerPanel = viewing_panel;
            obj.Axes = axes;
            obj.Axes3d = axes_3d;
            obj.Reporting = reporting;
        end

        function EnablePan(obj, enabled)
            obj.GetAxes.EnablePan(enabled);
            obj.GetAxes3d.EnablePan(enabled);
        end        
        
        function EnableZoom(obj, enabled)
            obj.GetAxes.EnableZoom(enabled);
            obj.GetAxes3d.EnableZoom(enabled);
        end
        
        function EnableRotate3d(obj, enabled)
            obj.GetAxes3d.EnableRotate3d(enabled);
        end
        
        function [min_coords, max_coords] = GetImageLimits(obj)
            % Gets the current limits of the visible image axes
 
            [min_coords, max_coords] = obj.GetAxes.GetImageLimits;
        end
        
        function SetImageLimits(obj, min_coords, max_coords)
            % Adjusts the image axes to make the image visible between the specified
            % coordinates
            
            x_lim = [min_coords(1), max_coords(1)];
            y_lim = [min_coords(2), max_coords(2)];
            obj.GetAxes.SetLimits(x_lim, y_lim);
        end
        
        function SetWindowWithinLimits(obj, window)
            % Sets the window subject to the current constraints
            
            window_limits = obj.ViewerPanel.WindowLimits;
            if ~isempty(window_limits)
                window = max(window, window_limits(1));
                window = min(window, window_limits(2));
                obj.ImageDisplayParameters.Window = window;
            end
        end

        function SetLevelWithinLimits(obj, level)
            % Sets the level subject to the current constraints
            
            level_limits = obj.ViewerPanel.LevelLimits;
            if ~isempty(level_limits)
                level = max(level, level_limits(1));
                level = min(level, level_limits(2));
                obj.ImageDisplayParameters.Level = level;
            end
        end

        function axes_handle = GetAxes(obj)
            axes_handle = obj.Axes;
            if isempty(axes_handle)
                obj.Reporting.Error('MimToolCallback:AxesDoNotExist', 'Axes have not been created');
            end
        end
        
        function axes_handle = GetAxes3d(obj)
            axes_handle = obj.Axes3d.GetRenderAxes;
            if isempty(axes_handle)
                obj.Reporting.Error('MimToolCallback:AxesDoNotExist', '3D Axes have not been created');
            end
        end
    end
end

