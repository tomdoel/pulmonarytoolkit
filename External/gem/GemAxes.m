classdef GemAxes < GemUserInterfaceObject
    % GemAxes GEM class for Matlab axes
    %
    %     GemAxes is used to build axes for supporting image display.
    %     By default the axes are always hidden, but they are required in order to
    %     define the image limits to display
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        XLim
        YLim
        HoldOnCreate = true
    end
    
    methods
        function obj = GemAxes(parent)
            obj = obj@GemUserInterfaceObject(parent);
            
            % Always hide the axes
            obj.VisibleParameter = 'off';
        end
        
        function CreateGuiComponent(obj, position)
            obj.GraphicalComponentHandle = axes('Parent', obj.Parent.GetContainerHandle, 'Units', 'pixels', 'Position', position, 'Visible', 'off');
            
            if ~isempty(obj.XLim)
                set(obj.GraphicalComponentHandle, 'XLim', obj.XLim, 'YLim', obj.YLim)
            end
            
            if obj.HoldOnCreate
                hold(obj.GraphicalComponentHandle, 'on');
            end
        end

        function current_point = GetCurrentPoint(obj)
            current_point = get(obj.GraphicalComponentHandle, 'CurrentPoint');
        end
        
        function SetContextMenu(obj, context_menu)
            set(obj.GraphicalComponentHandle, 'uicontextmenu', context_menu);
        end
        
        function EnablePan(obj, enabled)
            if ~isempty(obj.GraphicalComponentHandle)
                if enabled
                    param = 'on';
                else
                    param = 'off';
                end
                obj.ClearCallbacks;
                pan(obj.GraphicalComponentHandle, param);
                if enabled
                    obj.RestoreCustomKeyPressCallback;
                end
            end
        end        
        
        function EnableZoom(obj, enabled)
            if ~isempty(obj.GraphicalComponentHandle)
                if enabled
                    param = 'on';
                else
                    param = 'off';
                end
                obj.ClearCallbacks;
                zoom(obj.GraphicalComponentHandle, param);
                if enabled
                    obj.RestoreCustomKeyPressCallback;
                end
            end
        end
        
        function EnableRotate3d(obj, enabled)
            if ~isempty(obj.GraphicalComponentHandle)
                if enabled
                    param = 'on';
                else
                    param = 'off';
                end
                obj.ClearCallbacks;
                rotate3d(obj.GraphicalComponentHandle, param);
                if enabled
                    obj.RestoreCustomKeyPressCallback;
                end
            end
        end
        
        function ResetZoom(obj)
            if ~isempty(obj.GraphicalComponentHandle)
                zoom(obj.GraphicalComponentHandle, 'reset');
            end
        end

        function Resize(obj, position)
            Resize@GemUserInterfaceObject(obj, position);
        end
        
        function SetLimitsAndRatio(obj, x_lim, y_lim, data_aspect_ratio, axes_reset_object)
            set(obj.GraphicalComponentHandle, 'XLim', x_lim, 'YLim', y_lim, 'DataAspectRatio', data_aspect_ratio);
            if isempty(axes_reset_object)
                obj.ResetZoom;
            else
                setappdata(obj.GraphicalComponentHandle, 'matlab_graphics_resetplotview', axes_reset_object);
            end
        end
        
        function SetLimits(obj, x_lim, y_lim)
            % Set the limits of the axes
            
            x_valid = ~isempty(x_lim) && x_lim(2) > x_lim(1);
            y_valid = ~isempty(y_lim) && y_lim(2) > y_lim(1);
            
            if x_valid
                obj.XLim = x_lim;
            end
            if y_valid
                obj.YLim = y_lim;
            end
            
            if ~isempty(obj.GraphicalComponentHandle)
                if x_valid && y_valid
                    set(obj.GraphicalComponentHandle, 'XLim', x_lim, 'YLim', y_lim)
                elseif x_valid
                    set(obj.GraphicalComponentHandle, 'XLim', x_lim)
                elseif y_valid
                    set(obj.GraphicalComponentHandle, 'YLim', y_lim)
                end
            end
        end

        function [x_lim, y_lim] = GetLimits(obj)
            x_lim = get(obj.GraphicalComponentHandle, 'XLim');
            y_lim = get(obj.GraphicalComponentHandle, 'YLim');
        end
                
        function [min_coords, max_coords] = GetImageLimits(obj)
            % Gets the current limits of the visible image axes
            
            [x_lim, y_lim] = obj.GetLimits;
            min_coords = [x_lim(1), y_lim(1)];
            max_coords = [x_lim(2), y_lim(2)];
        end
        
        function frame = Capture(obj, xlim_image, ylim_image)
            % Captures the image from the current axes as a frame
            
            % Matlab cannot capture images on a secondary monitor, so we must
            % move the figure to the primary monitor
            old_position = get(obj.GraphicalComponentHandle, 'Position');
            movegui(obj.GraphicalComponentHandle);
            
            % Fetch the current screen coordinates of the axes
            rect_screenpixels = get(obj.GraphicalComponentHandle, 'Position');
            
            rect_screenpixels(1:2) = obj.GetScreenPosition;
            
            % The image may not occupy the entire axes, so we need to crop the
            % rectangle to only include the image
            xlim = get(obj.GraphicalComponentHandle, 'XLim');
            ylim = get(obj.GraphicalComponentHandle, 'YLim');

            x_size_screenpixels = rect_screenpixels(3);
            x_size_imagepixels = xlim(2) - xlim(1);
            scale_x = x_size_screenpixels/x_size_imagepixels;
            y_size_screenpixels = rect_screenpixels(4);
            y_size_imagepixels = ylim(2) - ylim(1);
            scale_y = y_size_screenpixels/y_size_imagepixels;
            
            
            x_offset_imagevoxels = max(0, xlim_image(1) - xlim(1));
            x_offset_screenvoxels = x_offset_imagevoxels*scale_x;
            
            x_endoffset_imagevoxels = max(0, xlim(2) - xlim_image(2));
            x_endoffset_screenvoxels = x_endoffset_imagevoxels*scale_x;

            y_offset_imagevoxels = max(0, ylim_image(1) - ylim(1));
            y_offset_screenvoxels = y_offset_imagevoxels*scale_y;
            
            y_endoffset_imagevoxels = max(0, ylim(2) - ylim_image(2));
            y_endoffset_screenvoxels = y_endoffset_imagevoxels*scale_y;

            % Crop the image rectangle so it only contains the image
            rect_screenpixels(1) = rect_screenpixels(1) + x_offset_screenvoxels;
            rect_screenpixels(2) = rect_screenpixels(2) + y_offset_screenvoxels;
            rect_screenpixels(3) = rect_screenpixels(3) - x_offset_screenvoxels - x_endoffset_screenvoxels;
            rect_screenpixels(4) = rect_screenpixels(4) - y_offset_screenvoxels - y_endoffset_screenvoxels;
            rect_screenpixels = round(rect_screenpixels);

            % Capture the image as a bitmap
            frame = GemUtilities.CaptureFigure(obj.GetParentFigure.GetContainerHandle, rect_screenpixels); %TODO
            
            % Return the figure to its original position 
            set(obj.GraphicalComponentHandle, 'Position', old_position);            
        end
        
        function Clear(obj)
            if ~isempty(obj.GraphicalComponentHandle)
                cla(obj.GraphicalComponentHandle, 'reset');
            end
        end
    end

    methods (Access = protected)
        
        function input_has_been_processed = MouseDown(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is clicked inside the control
            
            input_has_been_processed = obj.MatlabMouseDown(click_point, selection_type, src, eventdata);
        end

        function input_has_been_processed = MouseUp(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is clicked inside the control

            input_has_been_processed = obj.MatlabMouseUp(click_point, selection_type, src, eventdata);
        end
        
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is clicked inside the control

            input_has_been_processed = obj.MatlabMouseHasMoved(click_point, selection_type, src, eventdata);
        end
        
        function input_has_been_processed = MouseDragged(obj, click_point, selection_type, src, eventdata)
            % This method is called when the mouse is clicked inside the control

            input_has_been_processed = obj.MatlabMouseDragged(click_point, selection_type, src, eventdata);
        end
        
        function input_has_been_processed = Scroll(obj, click_point, scroll_count, src, eventdata)
            % This method is called when the mouse is clicked inside the control
            
            input_has_been_processed = obj.MatlabScroll(click_point, scroll_count, src, eventdata);
        end
    end
end