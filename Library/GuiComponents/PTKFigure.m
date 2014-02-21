classdef PTKFigure < PTKUserInterfaceObject
    % PTKFigure. Gui for choosing a dataset to view
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        Title
    end
    
    properties (Access = protected)
        ArrowPointer
    end
    
    properties (Access = private)
        CachedTitle
        OldResizeFunction;
        OldWindowScrollWheelFunction
    end

    methods
        function obj = PTKFigure(title, position)
            obj = obj@PTKUserInterfaceObject([]);
            obj.Title = title;
            obj.ArrowPointer = 'arrow';
            
            % Set the initial position. If this is not set, you must call
            % Resize() to set a position before making the figure visible
            if ~isempty(position)
                obj.Resize(position);
            end
        end

        function delete(obj)
            if ishandle(obj.GraphicalComponentHandle)
                % Remove custom handlers
                set(obj.GraphicalComponentHandle, 'ResizeFcn', @obj.OldResizeFunction);
                set(obj.GraphicalComponentHandle, 'WindowScrollWheelFcn', @obj.OldWindowScrollWheelFunction);
            end
        end
        
        function set.Title(obj, title)
            obj.Title = title;
            if ishandle(obj.GraphicalComponentHandle)
                set(obj.FigureHandle, 'Name', title);
            end
        end
        
        function BringToFront(obj)
            if obj.ComponentHasBeenCreated
                figure(obj.GraphicalComponentHandle);
            end
        end
        
        function CreateGuiComponent(obj, position, reporting)
            obj.GraphicalComponentHandle = figure('Color', PTKSoftwareInfo.BackgroundColour, 'Visible', 'off', ...
                'numbertitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
                'Units', 'pixels', 'Position', position, 'Name', obj.Title, 'Pointer', obj.ArrowPointer);
            
            % Store old custom handlers for this figure
            obj.OldWindowScrollWheelFunction = get(obj.GraphicalComponentHandle, 'WindowScrollWheelFcn');
            obj.OldResizeFunction = get(obj.GraphicalComponentHandle, 'ResizeFcn');
            
            % Set custom handlers
            set(obj.GraphicalComponentHandle, 'CloseRequestFcn', @obj.CustomCloseFunction);
            set(obj.GraphicalComponentHandle, 'WindowScrollWheelFcn', @obj.CustomWindowScrollWheelFunction);
            set(obj.GraphicalComponentHandle, 'WindowButtonDownFcn', @obj.CustomWindowButtonDownFunction);

            set(obj.GraphicalComponentHandle, 'ResizeFcn', @obj.CustomResize);
        end
        
        function Resize(obj, position)
            width_pixels = max(1, position(3));
            height_pixels = max(1, position(4));
            new_position = [position(1) position(2) width_pixels height_pixels];
            
            Resize@PTKUserInterfaceObject(obj, new_position);
        end

    end

    methods (Access = protected)
        
        function CustomResize(obj, eventdata, handles)
            parent_position = get(obj.GraphicalComponentHandle, 'Position');
            obj.LockResize = true;
            obj.Resize(parent_position);
            obj.LockResize = false;
            
            if (~isempty(obj.OldResizeFunction))
                obj.OldResizeFunction(eventdata, handles);
            end
        end

        function CustomCloseFunction(obj, ~, ~)
            % Our default figure behaviour is to destroy the object and its
            % controls on close
            delete(obj);
        end

        function CustomWindowButtonDownFunction(obj, src, eventdata)
            obj.CallMouseDown(get(src, 'CurrentPoint') + obj.Position(1:2) - 1);
        end
        
        
        function CustomWindowScrollWheelFunction(obj, src, eventdata)
            current_point = get(obj.GraphicalComponentHandle, 'CurrentPoint');
            scroll_count = eventdata.VerticalScrollCount; % positive = scroll down
            
            % Give the child controls the option of processing scrollwheel input
            for child = obj.Children
                if (child{1}.Scroll(scroll_count, current_point))
                    return;
                end
            end
               
            % If no child has processed the scrollwheel input then call the old handler
            if (~isempty(obj.OldWindowScrollWheelFunction))
                obj.OldWindowScrollWheelFunction(src, eventdata);
            end
        end

    end
end