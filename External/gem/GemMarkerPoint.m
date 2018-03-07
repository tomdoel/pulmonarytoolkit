classdef GemMarkerPoint < CoreBaseClass
    % GemMarkerPoint. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %     A GemMarkerPoint object is created for each marker currently displayed
    %     on the image. The purpose behind this class is to store the previous
    %     marker position in order to remove points from the underlying marker
    %     image when markers are moved.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        Colour
    end
    
    properties (Constant)
        % Blue, Green, Red, Cyan, Magenta, Yellow, Grey, Black
        DefaultColours = {[0.4 0.4 1.0], [0 0.8 0], [0.8 0 0], [0 0.8 0.8], [0.9 0 0.9],  [0.8 0.8 0.4], [0.7 0.7 0.7], [0.1 0.1 0.1]}
    end
    
    properties (Access = private)
        Handle
        Colours
        Manager
        HighlightColour = false
        Position
        LabelOn = false
        String = ''
        CallbackId
        FigureHandle
    end
    
    methods
        function obj = GemMarkerPoint(coords, axes_handle, colour, manager, coord_limits)
            obj.Colour = colour;
            obj.Colours = obj.DefaultColours;
            obj.Manager = manager;
            limits_x = [1, coord_limits(2)];
            limits_y = [1, coord_limits(1)];
            constraint_function = makeConstrainToRectFcn('impoint', limits_x, limits_y);
            obj.Handle = impoint(axes_handle.GetContainerHandle, coords(1), coords(2));
            obj.Handle.setPositionConstraintFcn(constraint_function);
            obj.Handle.addNewPositionCallback(@obj.PositionChangedCallback);
            obj.Handle.setColor(obj.Colours{colour});
            obj.FigureHandle = axes_handle.GetParentFigure;
            obj.CallbackId = obj.FigureHandle.RegisterMarkerPoint(obj.Handle);
            obj.AddContextMenu(obj.FigureHandle.GetContainerHandle);
            obj.Position = round(obj.Handle.getPosition);
        end
        
        function delete(obj)
            if ~isempty(obj.FigureHandle) && isvalid(obj.FigureHandle)
                obj.FigureHandle.UnRegisterMarkerPoint(obj.Handle, obj.CallbackId);
            end
        end
        
        function AddTextLabel(obj)
            obj.LabelOn = true;
            image_coords = obj.Manager.GetGlobalImageCoordinates(obj.Handle.getPosition);
            image_coords = round(image_coords);
            coords_text = ['(' int2str(image_coords(2)) ',' int2str(image_coords(1)) ',' int2str(image_coords(3)) ')'];
            if ~strcmp(coords_text, obj.String)
                obj.Handle.setString(coords_text);
                obj.String = coords_text;
            end
        end

        function RemoveTextLabel(obj)
            obj.LabelOn = false;
            obj.String = '';
            obj.Handle.setString('');
        end
        
        function coords = GetPosition(obj)
            coords = obj.Handle.getPosition;
        end
        
        function Highlight(obj)
            current_colour = obj.Handle.getColor;
            current_colour = min(1, current_colour + 0.3);
            obj.Handle.setColor(current_colour);
            obj.HighlightColour = true;
        end
        
        function HighlightOff(obj)
            if obj.HighlightColour
                obj.Handle.setColor(obj.Colours{obj.Colour});
                obj.HighlightColour = false;
            end
        end
        
        function ChangePosition(obj, coords)
            obj.Handle.setPosition(coords(1), coords(2));
            obj.Manager.AddPointToMarkerImage(obj.Position, 0);
            obj.Position = round(coords);
            obj.Manager.AddPointToMarkerImage(obj.Position, obj.Colour);
            if obj.LabelOn
                obj.AddTextLabel;
            end
        end
        
        function RemoveGraphic(obj)
            delete(obj.Handle);
        end
        
        function DeleteMarker(obj)
            obj.Manager.AddPointToMarkerImage(obj.Position, 0);
            obj.Manager.RemoveThisMarker(obj)
            obj.RemoveGraphic();
        end
    end
    
    methods (Access = private)
        function AddContextMenu(obj, figure_handle)
            marker_menu = uicontextmenu('Parent', figure_handle);
            marker_menu_delete = @(x, y) obj.DeleteMarkerCallback(x, y);
            marker_menu_blue = @(x, y) obj.ChangeMarkerColourCallback(x, y, 1);
            marker_menu_green = @(x, y) obj.ChangeMarkerColourCallback(x, y, 2);
            marker_menu_red = @(x, y) obj.ChangeMarkerColourCallback(x, y, 3);
            marker_menu_cyan = @(x, y) obj.ChangeMarkerColourCallback(x, y, 4);
            marker_menu_magenta = @(x, y) obj.ChangeMarkerColourCallback(x, y, 5);
            marker_menu_yellow = @(x, y) obj.ChangeMarkerColourCallback(x, y, 6);
            marker_menu_grey = @(x, y) obj.ChangeMarkerColourCallback(x, y, 7);
            
            uimenu(marker_menu, 'Label', 'Delete marker', 'Callback', marker_menu_delete);
            uimenu(marker_menu, 'Label', 'Change marker colour to:', 'Separator', 'on', 'Enable', 'off');
            uimenu(marker_menu, 'Label', '  Blue', 'Callback', marker_menu_blue, 'ForegroundColor', obj.Colours{1});
            uimenu(marker_menu, 'Label', '  Green', 'Callback', marker_menu_green, 'ForegroundColor', obj.Colours{2});
            uimenu(marker_menu, 'Label', '  Red', 'Callback', marker_menu_red, 'ForegroundColor', obj.Colours{3});
            uimenu(marker_menu, 'Label', '  Cyan', 'Callback', marker_menu_cyan, 'ForegroundColor', obj.Colours{4});
            uimenu(marker_menu, 'Label', '  Magenta', 'Callback', marker_menu_magenta, 'ForegroundColor', obj.Colours{5});
            uimenu(marker_menu, 'Label', '  Yellow', 'Callback', marker_menu_yellow, 'ForegroundColor', obj.Colours{6});
            uimenu(marker_menu, 'Label', '  Grey', 'Callback', marker_menu_grey, 'ForegroundColor', obj.Colours{7});
            set(obj.Handle, 'uicontextmenu', marker_menu)
        end

        function ChangeMarkerColourCallback(obj, ~, ~, colour)
            obj.Colour = colour;
            obj.Handle.setColor(obj.Colours{colour});
%             obj.Manager.ChangeCurrentColour(colour); %ToDo
            obj.Manager.AddPointToMarkerImage(obj.Position, colour);
        end
        
        function DeleteMarkerCallback(obj, ~, ~)
            obj.DeleteMarker;
        end
        
        function PositionChangedCallback(obj, new_position)
            obj.Manager.AddPointToMarkerImage(obj.Position, 0);
            obj.Position = round(new_position);
            obj.Manager.AddPointToMarkerImage(obj.Position, obj.Colour);
            if obj.LabelOn
                obj.AddTextLabel;
            end
        end
    end
end