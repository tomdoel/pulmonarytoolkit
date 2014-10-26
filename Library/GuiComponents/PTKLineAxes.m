classdef PTKLineAxes < PTKAxes
    % PTKLineAxes. Used to draw a line on a GUI
    %
    %     This class is a PTK graphical user interface component
    %
    %     PTKLineAxes is used to add a line to a GUI, by creating axes and attaching
    %     the line to the axes.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
        function obj = PTKLineAxes(parent)
            obj = obj@PTKAxes(parent);
            obj.LineColour = [0.5, 0.5, 0.5];
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKAxes(obj, position, reporting);
            
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
            Resize@PTKAxes(obj, position);
            
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