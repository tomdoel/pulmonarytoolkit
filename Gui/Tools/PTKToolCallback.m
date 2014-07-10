classdef PTKToolCallback < handle
    % PTKToolCallback. 
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
        Reporting
        Toolbar
        ViewerPanel
        ViewerPanelRenderer
    end
    
    methods
        
        function obj = PTKToolCallback(viewing_panel, reporting)
            obj.ViewerPanel = viewing_panel;
            obj.Reporting = reporting;
        end

        function SetToolbar(obj, toolbar)
            if isempty(toolbar)
                obj.Reporting.Error('PTKToolCallback:ToolbarDoNotExist', 'SetToolbar() was called with an empty toolbar');
            end
            
            obj.Toolbar = toolbar;
        end
        
        function SetRenderer(obj, viewer_panel_renderer)
            if isempty(viewer_panel_renderer)
                obj.Reporting.Error('PTKToolCallback:RendererDoesNotExist', 'SetRendererAndAxes() was called with empty viewer_panel_renderer');
            end
            obj.ViewerPanelRenderer = viewer_panel_renderer;
        end

        function EnablePan(obj, enabled)
            obj.GetAxes.EnablePan(enabled);
        end        
        
        function EnableZoom(obj, enabled)
            obj.GetAxes.EnableZoom(enabled);
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
            
            if isempty(obj.Toolbar)
                obj.Reporting.Error('PTKToolCallback:ToolbarDoesNotExist', 'Toolbar has not been set');
            end
            [window_min, window_max] = obj.Toolbar.GetWindowLimits;
            window = max(window, window_min);
            window = min(window, window_max);
            obj.ViewerPanel.Window = window;            
        end

        function SetLevelWithinLimits(obj, level)
            % Sets the level subject to the current constraints
            
            if isempty(obj.Toolbar)
                obj.Reporting.Error('PTKToolCallback:ToolbarDoesNotExist', 'Toolbar has not been set');
            end            
            [level_min, level_max] = obj.Toolbar.GetLevelLimits;
            level = max(level, level_min);
            level = min(level, level_max);
            obj.ViewerPanel.Level = level;
        end

        function axes_handle = GetAxes(obj)
            axes_handle = obj.ViewerPanelRenderer.GetAxes;
            if isempty(axes_handle)
                obj.Reporting.Error('PTKToolCallback:AxesDoNotExist', 'Axes have not been created');
            end
        end
        
        function axes_handle = GetAxesHandle(obj)
            axes_handle = obj.GetAxes.GetContainerHandle;
        end
        
    end
end

