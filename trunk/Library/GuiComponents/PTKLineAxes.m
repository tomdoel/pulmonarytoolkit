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
        LineObject
        LinePosition
    end
    
    properties
        LineColour
    end
    
    methods
        function obj = PTKLineAxes(parent, line_position)
            obj = obj@PTKAxes(parent);
            obj.LinePosition = line_position;
            obj.LineColour = [0.5, 0.5, 0.5];
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKAxes(obj, position, reporting);
            switch obj.LinePosition
                case 'left'
                    x_position = [1, 1];
                    y_position = [position(2), position(2) + position(4)];
                case 'right'
                    x_position = [position(3), position(3)];
                    y_position = [position(2), position(2) + position(4)];
                case 'top'
                    x_position = [1, position(3)];
                    y_position = [position(4) - 3, position(4) - 3];
                case 'bottom'
                    x_position = [1, position(3)];
                    y_position = [position(2) + 1, position(2) + 1];
                otherwise
                    reporting.Error('PTKLineAxes:UnknownLinePosition', 'Code error: the specified line position is unknown');
            end
            obj.LineObject = line('parent', obj.GraphicalComponentHandle, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
        end

        function Resize(obj, position)
            Resize@PTKAxes(obj, position);
            switch obj.LinePosition
                case 'left'
                    x_position = [1, 1];
                    y_position = [1, position(2) + position(4)];
                    x_limits = [1, position(3)];
                    y_limits = [1, position(4)];
                case 'right'
                    x_position = [position(3), position(3)];
                    y_position = [position(2), position(2) + position(4)];
                    x_limits = [1, position(3)];
                    y_limits = [1, position(4)];
                case 'top'
                    x_position = [1, position(3)];
                    y_position = [position(4) - 3, position(4) - 3];
                    x_limits = [1, position(3)];
                    y_limits = [1, position(4)];
                case 'bottom'
                    x_position = [1, position(3)];
                    y_position = [position(2) + 1, position(2) + 1];
                    x_limits = [1, position(3)];
                    y_limits = [1, position(4)];
                otherwise
                    reporting.Error('PTKLineAxes:UnknownLinePosition', 'Code error: the specified line position is unknown');
            end
            obj.SetLimits(x_limits, y_limits);
            set(obj.LineObject, 'XData', x_position, 'YData', y_position);
        end
        
    end
end