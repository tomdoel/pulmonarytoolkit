classdef MimMarkerPointTool < MimTool
    % MimMarkerPointTool. Part of the internal gui for the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the TD MIM Toolkit.
    %
    %     MimMarkerPointTool provides functionality for creating, editing and
    %     deleting marker points associated with an image using the
    %     MimViewerPanel.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Mark'
        Cursor = 'cross'
        ToolTip = 'Add or modify marker points.'
        Tag = 'Mark'
        ShortcutKey = 'm'
    end
  
    properties
        % When a marker is placed in close proximity to an existing marker of
        % the same colour, we assume that the user is actually trying to replace
        % the marker.
        ClosestDistanceForReplaceMarker = 5
    end
        
    properties (Access = private)
        MarkerLayer
        ViewerPanel
        DefaultColour = 3;
        IsDragging = false
    end
    
    methods
        function obj = MimMarkerPointTool(marker_layer, viewer_panel)
            obj.MarkerLayer = marker_layer;
            obj.ViewerPanel = viewer_panel;
        end

        function Enter(obj)
            % When the marker tool is selected, make existing markers
            % visible if they aren't already
            if ~obj.ViewerPanel.ShowMarkers
                obj.ViewerPanel.ShowMarkers = true;
            end
        end
        
        function Exit(obj)
            if obj.ViewerPanel.ShowMarkers
                obj.ViewerPanel.ShowMarkers = false;
            end            
        end
        
        function processed = Keypressed(obj, key_name)
            processed = true;
            if strcmpi(key_name, '1') % one
                obj.ChangeCurrentColour(1);
            elseif strcmpi(key_name, '2')
                obj.ChangeCurrentColour(2);
            elseif strcmpi(key_name, '3')
                obj.ChangeCurrentColour(3);
            elseif strcmpi(key_name, '4')
                obj.ChangeCurrentColour(4);
            elseif strcmpi(key_name, '5')
                obj.ChangeCurrentColour(5);
            elseif strcmpi(key_name, '6')
                obj.ChangeCurrentColour(6);
            elseif strcmpi(key_name, '7')
                obj.ChangeCurrentColour(7);
            elseif strcmpi(key_name, 'space')
                obj.ViewerPanel.GotoNearestMarker;
            elseif strcmpi(key_name, 'delete')
                obj.MarkerLayer.DeleteHighlightedMarker;
            elseif strcmpi(key_name, 'backspace')
                obj.MarkerLayer.DeleteHighlightedMarker;
            elseif strcmpi(key_name, 'leftarrow')
                obj.ViewerPanel.GotoPreviousMarker;
            elseif strcmpi(key_name, 'rightarrow')
                obj.ViewerPanel.GotoNextMarker;
            elseif strcmpi(key_name, 'leftbracket')
                obj.ViewerPanel.GotoFirstMarker;
            elseif strcmpi(key_name, 'rightbracket')
                obj.ViewerPanel.GotoLastMarker;
            else
                processed = false;
            end
        end

        function MouseDown(obj, ~)
            obj.IsDragging = false;
        end
        
        function AlertDragging(obj)
            obj.IsDragging = true;
        end
        
        function MouseHasMoved(obj, coords, last_coords)
            if obj.Enabled
                closest_marker = obj.GetMarkerForThisPoint(coords, []);
                if isempty(closest_marker)
                    obj.MarkerLayer.HighlightNone;
                else
                    obj.MarkerLayer.HighlightMarker(closest_marker);
                end
            end
        end

        function MouseUp(obj, coords)
            if obj.Enabled
                if ~obj.IsDragging
                    closest_marker = obj.GetMarkerForThisPoint(coords, obj.ViewerPanel.NewMarkerColour);
                    if isempty(closest_marker)
                        current_colour = obj.ViewerPanel.NewMarkerColour;
                        if isempty(current_colour)
                            current_colour = obj.DefaultColour;
                        end;
                        
                        new_marker = obj.MarkerLayer.AddMarker(coords, current_colour);
                        obj.MarkerLayer.HighlightMarker(new_marker);
                    else
                        closest_marker.ChangePosition(coords);
                    end
                end
            end
        end

        function ChangeCurrentColour(obj, new_colour)
            obj.ViewerPanel.NewMarkerColour = new_colour;
        end
    end

    methods (Access = private)        
        function closest_marker = GetMarkerForThisPoint(obj, coords, desired_colour)
            [closest_marker, closest_distance] = obj.GetNearestMarker(coords, desired_colour);
            if closest_distance > obj.ClosestDistanceForReplaceMarker
                closest_marker = [];
            end
        end

        function [closest_point, closest_distance] = GetNearestMarker(obj, coords, desired_colour)
            closest_point = [];
            closest_distance = [];
            for marker = obj.MarkerLayer.GetMarkerPoints
                if isempty(desired_colour) || (desired_colour == marker.Colour)
                    point_position = marker.GetPosition;
                    distance = sum(abs(coords - point_position)); % Cityblock distance
                    if isempty(closest_distance) || (distance < closest_distance)
                        closest_distance = distance;
                        closest_point = marker;
                    end
                end
            end
        end
    end
end
