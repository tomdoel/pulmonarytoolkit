classdef GemPanel < GemUserInterfaceObject
    % GEM class for a panel
    %
    % .. Licence
    %    -------
    %    Part of GEM. https://github.com/tomdoel/gem
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = protected)
        BorderAxes
        InnerPosition
    end
    
    properties
        BackgroundColour
    end
    
    properties (SetObservable)
        BorderColour
    end
    
    properties (Dependent)
        LeftBorder
        RightBorder
        TopBorder
        BottomBorder
    end
    
    methods
        function obj = GemPanel(parent_handle)
            obj = obj@GemUserInterfaceObject(parent_handle);
            obj.BackgroundColour = obj.StyleSheet.BackgroundColour;
            obj.AddPostSetListener(obj, 'BorderColour', @obj.BorderColourChangedCallback);            
        end
        
        function CreateGuiComponent(obj, position)
            obj.GraphicalComponentHandle = uipanel('Parent', obj.Parent.GetContainerHandle, 'BorderType', 'none', 'Units', 'pixels', ...
                'BackgroundColor', obj.BackgroundColour, 'ForegroundColor', obj.StyleSheet.TextPrimaryColour, 'ResizeFcn', '', 'Position', position);
        end
        
        function Resize(obj, position)
            Resize@GemUserInterfaceObject(obj, position);
            
            if ~isempty(obj.BorderAxes)
                obj.BorderAxes.Resize([1, 1, position(3), position(4)]);
            end
            
            inner_position = [1, 1, position(3), position(4)];

            if obj.LeftBorder
                inner_position(1) = inner_position(1) + 1;
                inner_position(3) = inner_position(3) - 1;
            end
            if obj.RightBorder
                inner_position(3) = inner_position(3) - 1;
            end
            if obj.TopBorder
                % FIXME: -2 instead of -1 to ensure top line is visible
                inner_position(4) = inner_position(4) - 2;
            end
            if obj.BottomBorder
                inner_position(2) = inner_position(2) + 1;
                inner_position(4) = inner_position(4) - 1;
            end
            
            obj.InnerPosition = inner_position;
        end
        
        function inner_position = GetInnerPosition(obj, inner_position)
            % Gets the position minus any borders
            if obj.LeftBorder
                inner_position(1) = inner_position(1) + 1;
                inner_position(3) = inner_position(3) - 1;
            end
            if obj.RightBorder
                inner_position(3) = inner_position(3) - 1;
            end
            if obj.TopBorder
                % FIXME: -2 instead of -1 to ensure top line is visible
                inner_position(4) = inner_position(4) - 2;
            end
            if obj.BottomBorder
                inner_position(2) = inner_position(2) + 1;
                inner_position(4) = inner_position(4) - 1;
            end
        end
        
        function set.LeftBorder(obj, border)
            if border
                obj.lazyCreateBorderAxes();
            end
            if ~isempty(obj.BorderAxes)
                obj.BorderAxes.LeftLine = border;
            end
        end
        
        function border = get.LeftBorder(obj)
            if isempty(obj.BorderAxes)
                border = false;
            else
                border = obj.BorderAxes.LeftLine;
            end
        end        
        function set.RightBorder(obj, border)
            if border
                obj.lazyCreateBorderAxes();
            end
            if ~isempty(obj.BorderAxes)
                obj.BorderAxes.RightLine = border;
            end
        end
        
        function border = get.RightBorder(obj)
            if isempty(obj.BorderAxes)
                border = false;
            else
                border = obj.BorderAxes.RightLine;
            end
        end        
        function set.TopBorder(obj, border)
            if border
                obj.lazyCreateBorderAxes();
            end
            if ~isempty(obj.BorderAxes)
                obj.BorderAxes.TopLine = border;
            end
        end
        
        function border = get.TopBorder(obj)
            if isempty(obj.BorderAxes)
                border = false;
            else
                border = obj.BorderAxes.TopLine;
            end
        end        
        function set.BottomBorder(obj, border)
            if border
                obj.lazyCreateBorderAxes();
            end
            if ~isempty(obj.BorderAxes)
                obj.BorderAxes.BottomLine = border;
            end
        end
        
        function border = get.BottomBorder(obj)
            if isempty(obj.BorderAxes)
                border = false;
            else
                border = obj.BorderAxes.BottomLine;
            end
        end        
    end
    
    methods (Access = protected)
        function BorderColourChangedCallback(obj, ~, ~, ~)
            if ~isempty(obj.BorderAxes)
                obj.BorderAxes.LineColour = obj.BorderColour;
            end
        end
        
        function lazyCreateBorderAxes(obj)
            if isempty(obj.BorderAxes)
                obj.BorderAxes = GemLineAxes(obj);
                if ~isempty(obj.BorderColour)
                    obj.BorderAxes.LineColour = obj.BorderColour;
                end                
                obj.AddChild(obj.BorderAxes);
            end
        end
        
    end

end