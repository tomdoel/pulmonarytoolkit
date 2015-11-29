classdef GemLineAxes < GemAxes
    % GemLineAxes GEM class for drawing a line on a GUI
    %
    %     GemLineAxes is used to add a line to a GUI, by creating axes and attaching
    %     the line to the axes.
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        LeftLineObject
        RightLineObject
        TopLineObject
        BottomLineObject
    end

    properties
        LineColour
        LeftLine = false
        RightLine = false
        TopLine = false
        BottomLine = false
    end
    
    methods
        function obj = GemLineAxes(parent)
            obj = obj@GemAxes(parent);
            obj.LineColour = [0.5, 0.5, 0.5];
        end
        
        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemAxes(obj, position);
            
            if obj.LeftLine
                x_position = [position(1), position(2)];
                y_position = [position(2), position(2) + position(4) - 1];
                obj.LeftLineObject = line('parent', obj.GraphicalComponentHandle, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
            end
            if obj.RightLine
                x_position = [position(1) + position(3) - 1, position(1) + position(3) - 1];
                y_position = [position(2), position(2) + position(4) - 1];
                obj.RightLineObject = line('parent', obj.GraphicalComponentHandle, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
            end
            if obj.TopLine
                x_position = [position(1), position(1) + position(3) - 1];
                y_position = [position(2) + position(4) - 1, position(2) + position(4) - 1];
                obj.TopLineObject = line('parent', obj.GraphicalComponentHandle, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
            end
            if obj.BottomLine
                x_position = [position(1), position(1) + position(3) - 1];
                y_position = [position(2), position(2)];
                obj.BottomLineObject = line('parent', obj.GraphicalComponentHandle, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
            end
        end

        function Resize(obj, position)
            Resize@GemAxes(obj, position);
            
            % Ensure the limits are outside of the border lines, otherwise
            % they might not draw correctly
            x_limits = [0, position(3) + 1];
            y_limits = [0, position(4) + 1];

            obj.SetLimits(x_limits, y_limits);
            
            if ishandle(obj.LeftLineObject)
                x_position = [position(1), position(1)];
                y_position = [position(2), position(2) + position(4) - 1];
                set(obj.LeftLineObject, 'XData', x_position, 'YData', y_position);
            end
            
            if ishandle(obj.RightLineObject)
                x_position = [position(1) + position(3) - 1, position(1) + position(3) - 1];
                y_position = [position(2), position(2) + position(4) - 1];
                set(obj.RightLineObject, 'XData', x_position, 'YData', y_position);
            end
            
            if ishandle(obj.TopLineObject)
                x_position = [position(1), position(1) + position(3) - 1];
                y_position = [position(2) + position(4) - 1, position(2) + position(4) - 1];
                set(obj.TopLineObject, 'XData', x_position, 'YData', y_position);
            end
            
            if ishandle(obj.BottomLineObject)
                x_position = [position(1), position(1) + position(3) - 1];
                y_position = [position(2), position(2)];
                set(obj.BottomLineObject, 'XData', x_position, 'YData', y_position);
            end
            
        end
        
    end
end