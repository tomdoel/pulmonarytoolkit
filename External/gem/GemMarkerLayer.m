classdef GemMarkerLayer < CoreBaseClass
    % GemMarkerLayer. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %     GemMarkerLayer displays marker points over an image
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        % Keep a record of when we have unsaved changes to markers
        MarkerImageHasChanged = false

        MarkersAreVisible = false
        TextLabelsAreVisible = false
    end
    
    properties (Access = private)
        Axes
        MarkerPointImage
        MarkerPoints
        MarkerDisplayParameters
        ImageSliceParameters
        ViewerPanel
        CurrentlyHighlightedMarker
        CoordinateLimits
        LockCallback = false
        IsDragging = false
    end
    
    methods
        function obj = GemMarkerLayer(marker_image_source, marker_display_parameters, viewer_panel, axes, image_slice_parameters)
            obj.ViewerPanel = viewer_panel;
            obj.Axes = axes;
            obj.ImageSliceParameters = image_slice_parameters;
            obj.MarkerDisplayParameters = marker_display_parameters;
            obj.MarkerPointImage = marker_image_source;
            obj.AddPostSetListener(image_slice_parameters, 'Orientation', @obj.OrientationChangedCallback);            
            obj.AddPostSetListener(image_slice_parameters, 'SliceNumber', @obj.SliceNumberChangedCallback);            
            obj.AddEventListener(obj.ViewerPanel.GetBackgroundImageSource, 'NewImage', @obj.BackgroundImageChangedCallback);
            obj.AddEventListener(obj.ViewerPanel.GetBackgroundImageSource, 'ImageModified', @obj.BackgroundImageChangedCallback);
            obj.AddEventListener(marker_image_source, 'NewImage', @obj.MarkerImageChangedCallback);
            obj.AddEventListener(marker_image_source, 'ImageModified', @obj.MarkerImageChangedCallback);            
            obj.AddPostSetListener(marker_display_parameters, 'ShowMarkers', @obj.ShowMarkersChangedCallback);
            obj.AddPostSetListener(marker_display_parameters, 'ShowLabels', @obj.ShowLabelsChangedCallback);
        end
        
        function ChangeMarkerSubImage(obj, new_image)
            obj.MarkerPointImage.ChangeMarkerSubImage(new_image);
            obj.MarkerImageChanged;
            obj.MarkerImageHasChanged = false;
        end
        
        function ShowMarkers(obj, show)
            if (show && ~obj.MarkersAreVisible)
                obj.ConvertMarkerImageToPoints(obj.ImageSliceParameters.SliceNumber(obj.ImageSliceParameters.Orientation), obj.ImageSliceParameters.Orientation);
            end
            
            if (~show && obj.MarkersAreVisible)
                obj.RemoveAllPoints;
            end
            
            obj.MarkersAreVisible = show;
        end

        function MarkerImageChanged(obj)
            if obj.MarkersAreVisible
                if ~obj.LockCallback
                    obj.RemoveAllPoints;
                    obj.ConvertMarkerImageToPoints(obj.ImageSliceParameters.SliceNumber(obj.ImageSliceParameters.Orientation), obj.ImageSliceParameters.Orientation);
                end
            end
        end

        function image_coords = GetImageCoordinates(obj, coords)
            image_coords = zeros(1, 3);
            i_screen = coords(2);
            j_screen = coords(1);
            k_screen = obj.ImageSliceParameters.SliceNumber(obj.ImageSliceParameters.Orientation);

            switch obj.ImageSliceParameters.Orientation
                case GemImageOrientation.XZ
                    image_coords(1) = k_screen;
                    image_coords(2) = j_screen;
                    image_coords(3) = i_screen;
                case GemImageOrientation.YZ
                    image_coords(1) = j_screen;
                    image_coords(2) = k_screen;
                    image_coords(3) = i_screen;
                case GemImageOrientation.XY
                    image_coords(1) = i_screen;
                    image_coords(2) = j_screen;
                    image_coords(3) = k_screen;
            end
        end
        
        function global_image_coords = GetGlobalImageCoordinates(obj, coords)
            local_image_coords = obj.GetImageCoordinates(coords);
            global_image_coords = obj.MarkerPointImage.LocalToGlobalCoordinates(local_image_coords);
        end

        function RemoveThisMarker(obj, marker)
            for index = 1: length(obj.MarkerPoints)
                indexed_marker = obj.MarkerPoints(index);
                if indexed_marker == marker
                    if (marker == obj.CurrentlyHighlightedMarker)
                        obj.CurrentlyHighlightedMarker = [];
                    end
                    obj.MarkerPoints(index) = [];
                    return;
                end
            end
        end

        function AddPointToMarkerImage(obj, marker_position, colour)
            obj.LockCallback = true;
            coords = obj.GetImageCoordinates(marker_position);
            
            if obj.MarkerPointImage.ChangeMarkerPoint(coords, colour)
                obj.MarkerImageHasChanged = true;
            end
            
            obj.LockCallback = false;
        end
                
        function MarkerPointsHaveBeenSaved(obj)
            obj.MarkerImageHasChanged = false;
        end
        
        function marker_image = GetMarkerImage(obj)
            marker_image = obj.MarkerPointImage;
        end

        function marker_points = GetMarkerPoints(obj)
            marker_points = obj.MarkerPoints;
        end
        
        function new_marker = AddMarker(obj, coords, colour)
            new_marker = obj.NewMarker(coords, colour);
        end
        
        function ChangeShowTextLabels(obj, show)
            if obj.MarkersAreVisible
                if show && ~obj.TextLabelsAreVisible
                    obj.ShowAllTextLabels;
                end
                if ~show && obj.TextLabelsAreVisible
                    obj.HideAllTextLabels;
                end
            end
            obj.TextLabelsAreVisible = show;
        end
        
        function HighlightNone(obj)
            if ~isempty(obj.CurrentlyHighlightedMarker)
                obj.CurrentlyHighlightedMarker.HighlightOff;
                obj.CurrentlyHighlightedMarker = [];
            end
        end
        
        function HighlightMarker(obj, marker)
            if isempty(obj.CurrentlyHighlightedMarker) || (obj.CurrentlyHighlightedMarker ~= marker)
                obj.HighlightNone;
                marker.Highlight;
                obj.CurrentlyHighlightedMarker = marker;
            end
        end
        
        function DeleteHighlightedMarker(obj)
            if ~isempty(obj.CurrentlyHighlightedMarker)
                obj.CurrentlyHighlightedMarker.DeleteMarker;
            end
        end
        
    end

    methods (Access = private)
        function ConvertMarkerImageToPoints(obj, slice_number, dimension)
            if obj.MarkerPointImage.MarkerImageExists
                [slice_markers, slice_size] = obj.MarkerPointImage.GetMarkersFromImage(slice_number, dimension);
                
                obj.CoordinateLimits = slice_size;
                
                for marker_s = slice_markers
                    marker = marker_s{1};
                    obj.NewMarker([marker.x, marker.y], marker.colour);
                end
            end
        end
                
        function new_marker = NewMarker(obj, coords, colour)
            obj.ForceMarkerImageCreation;
            if isempty(obj.CoordinateLimits)
                orientation = obj.ImageSliceParameters.Orientation;
                slice_number = obj.ImageSliceParameters.SliceNumber(orientation);
                [~, slice_size] = obj.MarkerPointImage.GetMarkersFromImage(slice_number, orientation);
                obj.CoordinateLimits = slice_size;                
            end
            
            new_marker = GemMarkerPoint(coords, obj.Axes, colour, obj, obj.GetCoordinateLimits);
            
            if isempty(obj.MarkerPoints)
                obj.MarkerPoints = new_marker;
            else
                obj.MarkerPoints(end+1) = new_marker;
            end
            
            if (obj.TextLabelsAreVisible)
                new_marker.AddTextLabel;
            end
        end
        
        function ShowAllTextLabels(obj)
            for marker = obj.MarkerPoints
                marker.AddTextLabel;
            end
        end

        function HideAllTextLabels(obj)
            for marker = obj.MarkerPoints
                marker.RemoveTextLabel;
            end
        end

        function RemoveAllPoints(obj)
            obj.CurrentlyHighlightedMarker = [];
            for marker = obj.MarkerPoints
                marker.RemoveGraphic;
            end
            obj.MarkerPoints = [];
        end
        
        function BackgroundImageChangedCallback(obj, ~, ~)
            obj.ImageChanged;
        end

        function limits = GetCoordinateLimits(obj)
            limits = obj.CoordinateLimits;
        end
        
        function SliceNumberChangedCallback(obj, ~, ~, ~)
            obj.NewSliceOrOrientation;
        end
        
        function OrientationChangedCallback(obj, ~, ~)
            obj.NewSliceOrOrientation;
        end
        
        function ShowMarkersChangedCallback(obj, ~, ~)
            obj.ShowMarkers(obj.MarkerDisplayParameters.ShowMarkers);
        end
        
        function ShowLabelsChangedCallback(obj, ~, ~)
            obj.ChangeShowTextLabels(obj.MarkerDisplayParameters.ShowLabels);
        end

        function MarkerImageChangedCallback(obj, ~, ~)
            obj.MarkerImageChanged;
        end
        
        function NewSliceOrOrientation(obj)
            if obj.MarkersAreVisible
                if ~obj.LockCallback
                    obj.RemoveAllPoints;
                    obj.ConvertMarkerImageToPoints(obj.ImageSliceParameters.SliceNumber(obj.ImageSliceParameters.Orientation), obj.ImageSliceParameters.Orientation);
                end
            end
        end
        
        function ImageChanged(obj)
            obj.MarkerPointImage.BackgroundImageChanged(obj.ViewerPanel.BackgroundImage);
            obj.MarkerImageChanged;
            obj.MarkerImageHasChanged = false;
        end
        
        function ForceMarkerImageCreation(obj)
            if ~obj.MarkerPointImage.Image.ImageExists
                obj.MarkerPointImage.ForceMarkerImageCreation(obj.ViewerPanel.BackgroundImage);
            end
        end
    end
end

