classdef PTKPanel < PTKUserInterfaceObject
    % PTKPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPanel is used to build panels with the user interface.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = protected)
        BorderAxes
        InnerPosition
        Reporting
    end
    
    properties
        BackgroundColour
        BorderColour
    end
    
    properties (SetObservable)
        LeftBorder = false
        RightBorder = false
        TopBorder = false
        BottomBorder = false
    end
    
    methods
        function obj = PTKPanel(parent_handle, reporting)
            obj = obj@PTKUserInterfaceObject(parent_handle);
            obj.BackgroundColour = PTKSoftwareInfo.BackgroundColour;
            if nargin > 1
                obj.Reporting = reporting;
            end

            % We listen to changes in the border properties so we know when
            % to create axes for the lines which comprise the borders
            obj.AddPostSetListener(obj, 'LeftBorder', @obj.BorderChangedCallback);
            obj.AddPostSetListener(obj, 'RightBorder', @obj.BorderChangedCallback);
            obj.AddPostSetListener(obj, 'TopBorder', @obj.BorderChangedCallback);
            obj.AddPostSetListener(obj, 'BottomBorder', @obj.BorderChangedCallback);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            if ~isempty(obj.BorderAxes)
                obj.BorderAxes.TopLine = obj.TopBorder;
                obj.BorderAxes.BottomLine = obj.BottomBorder;
                obj.BorderAxes.LeftLine = obj.LeftBorder;
                obj.BorderAxes.RightLine = obj.RightBorder;
                if ~isempty(obj.BorderColour)
                    obj.BorderAxes.Colour = obj.BorderColour;
                end
            end
            
            obj.GraphicalComponentHandle = uipanel('Parent', obj.Parent.GetContainerHandle(reporting), 'BorderType', 'none', 'Units', 'pixels', ...
                'BackgroundColor', obj.BackgroundColour, 'ForegroundColor', 'white', 'ResizeFcn', '', 'Position', position);
        end
        
        function Resize(obj, position)
            Resize@PTKUserInterfaceObject(obj, position);
            
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
    end
    
    methods (Access = protected)
        function BorderChangedCallback(obj, ~, ~, ~)
            if isempty(obj.BorderAxes) && (obj.LeftBorder || obj.RightBorder || obj.TopBorder || obj.BottomBorder)
                obj.BorderAxes = PTKLineAxes(obj);
                obj.AddChild(obj.BorderAxes, obj.Reporting);
            end
        end
    end

end