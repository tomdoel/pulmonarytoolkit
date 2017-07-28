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

    properties (SetObservable)
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
            
            % We listen to changes in the border properties so we know when
            % to create axes for the lines which comprise the borders
            obj.AddPostSetListener(obj, 'LineColour', @obj.LineChangedCallback);
            obj.AddPostSetListener(obj, 'LeftLine', @obj.LineChangedCallback);
            obj.AddPostSetListener(obj, 'RightLine', @obj.LineChangedCallback);
            obj.AddPostSetListener(obj, 'TopLine', @obj.LineChangedCallback);
            obj.AddPostSetListener(obj, 'BottomLine', @obj.LineChangedCallback);
        end
        
        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemAxes(obj, position);
            
            obj.UpdateBorders(position);
        end

        function Resize(obj, position)
            Resize@GemAxes(obj, position);
            
            % Ensure the limits are outside of the border lines, otherwise
            % they might not draw correctly
            x_limits = [0, position(3) + 1];
            y_limits = [0, position(4) + 1];

            obj.SetLimits(x_limits, y_limits);
            
            obj.UpdateBorders(position);
        end        
    end
    
    methods (Access = protected)
        function LineChangedCallback(obj, ~, ~, ~)
            obj.UpdateBorders(obj.Position);
        end
        
        function UpdateBorders(obj, position)
            if ~isempty(obj.GraphicalComponentHandle) && ~isempty(position)
                if obj.LeftLine
                    x_position = [position(1), position(2)];
                    y_position = [position(2), position(2) + position(4) - 1];
                    if ~isempty(obj.LeftLineObject) && ishandle(obj.LeftLineObject)
                        set(obj.LeftLineObject, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
                    else
                        obj.LeftLineObject = line('parent', obj.GraphicalComponentHandle, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
                    end
                elseif ~isempty(obj.LeftLineObject)
                    delete(obj.LeftLineObject);
                    obj.LeftLineObject = [];
                end

                if obj.RightLine
                    x_position = [position(1) + position(3) - 1, position(1) + position(3) - 1];
                    y_position = [position(2), position(2) + position(4) - 1];
                    if ~isempty(obj.RightLineObject) && ishandle(obj.RightLineObject)
                        set(obj.RightLineObject, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
                    else
                        obj.RightLineObject = line('parent', obj.GraphicalComponentHandle, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
                    end
                elseif ~isempty(obj.RightLineObject)
                    delete(obj.RightLineObject);
                    obj.RightLineObject = [];
                end

                if obj.TopLine
                    x_position = [position(1), position(1) + position(3) - 1];
                    y_position = [position(2) + position(4) - 1, position(2) + position(4) - 1];
                    if ~isempty(obj.TopLineObject) && ishandle(obj.TopLineObject)
                        set(obj.TopLineObject, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
                    else
                        obj.TopLineObject = line('parent', obj.GraphicalComponentHandle, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
                    end
                elseif ~isempty(obj.TopLineObject)
                    delete(obj.TopLineObject);
                    obj.TopLineObject = [];
                end

                if obj.BottomLine
                    x_position = [position(1), position(1) + position(3) - 1];
                    y_position = [position(2), position(2)];
                    if ~isempty(obj.BottomLineObject) && ishandle(obj.BottomLineObject)
                        set(obj.BottomLineObject, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
                    else
                        obj.BottomLineObject = line('parent', obj.GraphicalComponentHandle, 'XData', x_position, 'YData', y_position, 'color', obj.LineColour);
                    end
                elseif ~isempty(obj.BottomLineObject)
                    delete(obj.BottomLineObject);
                    obj.BottomLineObject = [];
                end
            end
        end
    end
end