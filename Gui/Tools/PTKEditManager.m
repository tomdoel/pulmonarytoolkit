classdef PTKEditManager < PTKTool
    % PTKEditManager. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Edit'
        Cursor = 'cross'
        RestoreKeyPressCallbackWhenSelected = false
        ToolTip = 'Manually edit current result.'
        Tag = 'Edit'
        ShortcutKey = 'e'
    end
    
    properties
        % When this is set to true, the outer boundary cannot be changed
        FixedOuterBoundary = true
        
        % When a marker is placed in close proximity to an existing marker of
        % the same colour, we assume that the user is actually trying to replace
        % the marker.
        ClosestDistanceForReplaceMarker = 10
    end
    
    properties (SetAccess = private)
        
        % Keep a record of when we have unsaved changes to markers
        MarkerImageHasChanged = false
        
    end
    
    properties (SetAccess = private, SetObservable)        
        % The colour that new markers will be set to
        CurrentColour
        
        BrushSize = 10
    end
    
    properties (Access = private)
        DTImage
        GaussianImage
        DT
        Colours
        
        ViewerPanel

        MarkerPointImage
        MarkerPoints
        CurrentlyHighlightedMarker
        SliceNumber
        Orientation
        CoordinateLimits
        LockCallback = false
        Enabled = false
        DefaultColour = 3;
        IsDragging = false
    end
    
    methods
        function obj = PTKEditManager(viewer_panel)
            obj.ViewerPanel = viewer_panel;
        end
        
        
        function Enable(obj, enable)
            if enable && isempty(obj.DTImage)
                obj.CreateEditedImage;
            end
            
            obj.Enabled = enable;
        end
        
        function processed = Keypress(obj, key_name)
            processed = false;
        end
        
        function NewSliceOrOrientation(obj)
        end
        
        function ImageChanged(obj)
            obj.InitialiseEditMode;
        end
        
        
        
        function InitialiseEditMode(obj)
                voxel_size = obj.ViewerPanel.OverlayImage.VoxelSize;
                obj.GaussianImage = PTKNormalisedGaussianKernel(voxel_size, obj.BrushSize);
                obj.Colours = unique(obj.ViewerPanel.OverlayImage.RawImage);
                
                if obj.FixedOuterBoundary
                    obj.Colours = setdiff(obj.Colours, 0);
                end
            
%             if isempty(obj.DT)
%                 reporting.UpdateProgressAndMessage(0, 'Initalising editor');
                obj.DT = zeros([obj.ViewerPanel.OverlayImage.ImageSize, numel(obj.Colours)]);
                for colour_index = 1 : numel(obj.Colours);
%                     reporting.UpdateProgressStage(colour_index, 1 + numel(obj.Colours));
                    colour = obj.Colours(colour_index);
                    obj.DT(:, :, :, colour_index) = bwdist(obj.ViewerPanel.OverlayImage.RawImage == colour);
                end
%                 reporting.CompleteProgress;
%             end

        end
        
        function [closest, second_closest] = GetClosestIndices(obj, local_image_coords)
            distances = obj.DT(local_image_coords(1), local_image_coords(2), local_image_coords(3), :);
            [~, sorted_indices] = sort(distances, 'ascend');
            closest = sorted_indices(1);
            second_closest = sorted_indices(2);
        end
        
        function [closest, second_closest] = GetClosestIndices2D(obj, local_image_coords)
            slice_number = obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation);
            image_slice = obj.ViewerPanel.OverlayImage.GetSlice(slice_number, obj.ViewerPanel.Orientation);
            
            dts = zeros([size(image_slice), numel(obj.Colours)]);
            
            for colour_index = 1 : numel(obj.Colours);
                colour = obj.Colours(colour_index);
                dts(:, :, colour_index) = bwdist(image_slice == colour);
            end
            
            distances = obj.DT(local_image_coords(1), local_image_coords(2), local_image_coords(3), :);
            [~, sorted_indices] = sort(distances, 'ascend');
            closest = sorted_indices(1);
            second_closest = sorted_indices(2);
        end
        
        function MouseDown(obj, coords)
            if isempty(obj.DT)
                obj.InitialiseEditMode;
            end

            image_size = obj.ViewerPanel.OverlayImage.ImageSize;
            
            obj.IsDragging = false;
            global_image_coords = round(obj.GetGlobalImageCoordinates(coords));
            local_image_coords = obj.ViewerPanel.OverlayImage.GlobalToLocalCoordinates(global_image_coords);
            
%             [closest, second_closest] = obj.GetClosestIndices(local_image_coords);
            [closest, second_closest] = obj.GetClosestIndices2D(local_image_coords);
            
            closest_colour = obj.Colours(closest);
            second_closest_colour = obj.Colours(second_closest);
            
            local_size = size(obj.GaussianImage);
            
            min_coords = local_image_coords - floor(local_size/2);
            max_coords = local_image_coords + floor(local_size/2);
            
            min_clipping = max(0, 1 - min_coords);
            max_clipping = max(0, max_coords - image_size);
            
            min_coords = max(1, min_coords);
            max_coords = min(max_coords, image_size);
            
            raw_image = obj.ViewerPanel.OverlayImage.RawImage;
            subimage = raw_image(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3));
            dt_subimage_second = obj.DT(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3), second_closest);
            dt_subimage_first = obj.DT(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3), closest);
            
            dt_value = obj.DT(local_image_coords(1), local_image_coords(2), local_image_coords(3), second_closest);
            
            brush_min_coords = 1 + min_clipping;
            brush_max_coords = size(obj.GaussianImage) - max_clipping;
            
            
            add_mask = -dt_value*obj.GaussianImage;
            add_mask = add_mask(brush_min_coords(1) : brush_max_coords(1), brush_min_coords(2) : brush_max_coords(2), brush_min_coords(3) : brush_max_coords(3));
            
            dt_subimage_second = dt_subimage_second + add_mask;
            dt_subimage_first = dt_subimage_first - add_mask;
            obj.DT(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3), second_closest) = dt_subimage_second;
            obj.DT(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3), closest) = dt_subimage_first;

            old_subimage = subimage;
            
            subimage(old_subimage == closest_colour & dt_subimage_second <= 0) = second_closest_colour;
%             subimage(old_subimage == second_closest_colour & dt_subimage_second > 0) = closest_colour;
            
            raw_image(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3)) = subimage;
            obj.ViewerPanel.OverlayImage.ChangeRawImage(raw_image);

%             obj.InitialiseEditMode;
            
            
%             ball = PTKImageUtilities.CreateBallStructuralElement(obj.ViewerPanel.OverlayImage.VoxelSize, 30);
%             
%             
%             
%             
%             colours = unique(subimage);
%             dt = zeros([size(subimage), numel(colours)]);
%             for colour_index = 1 : numel(colours);
%                 colour = colours(colour_index);
%                 dt(:, :, :,colour_index) = bwdist(subimage == colour);
%             end
%             [~, nearest_colour] = min(dt, [], 4);
%             nearest_colour(local_image_coords(1), local_image_coords(2), local_image_coords(3))
%             
%             
%             
%             subimage(:) = 3;
%             
%             raw_image(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3)) = subimage;
%             obj.ViewerPanel.OverlayImage.ChangeRawImage(raw_image);
            
%             obj.ViewerPanel.OverlayImage.SetVoxelToThis(round(global_image_coords), 3);
        end
        
        function AlertDragging(obj)
            obj.IsDragging = true;
        end
        
        function MouseHasMoved(obj, viewer_panel, coords, last_coords, mouse_is_down)
%             if obj.Enabled
%                 closest_marker = obj.GetMarkerForThisPoint(coords, []);
%                 if isempty(closest_marker)
%                     obj.HighlightNone;
%                 else
%                     obj.HighlightMarker(closest_marker);
%                 end
%             end
        end        
        
        function MouseUp(obj, coords)
%             if obj.Enabled
%                 if ~obj.IsDragging
%                     closest_marker = obj.GetMarkerForThisPoint(coords, obj.CurrentColour);
%                     if isempty(closest_marker)
%                         current_colour = obj.CurrentColour;
%                         if isempty(current_colour)
%                             current_colour = obj.DefaultColour;
%                         end;
%                         
%                         new_marker = obj.NewMarker(coords, current_colour);
%                         obj.HighlightMarker(new_marker);
%                     else
%                         closest_marker.ChangePosition(coords);
%                     end
%                 end
%             end
        end

        function image_coords = GetImageCoordinates(obj, coords)
            image_coords = zeros(1, 3);
            i_screen = coords(2);
            j_screen = coords(1);
            k_screen = obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation);
            
            switch obj.ViewerPanel.Orientation
                case PTKImageOrientation.Coronal
                    image_coords(1) = k_screen;
                    image_coords(2) = j_screen;
                    image_coords(3) = i_screen;
                case PTKImageOrientation.Sagittal
                    image_coords(1) = j_screen;
                    image_coords(2) = k_screen;
                    image_coords(3) = i_screen;
                case PTKImageOrientation.Axial
                    image_coords(1) = i_screen;
                    image_coords(2) = j_screen;
                    image_coords(3) = k_screen;
            end
        end
        
        function global_image_coords = GetGlobalImageCoordinates(obj, coords)
            local_image_coords = obj.GetImageCoordinates(coords);
            global_image_coords = obj.ViewerPanel.BackgroundImage.LocalToGlobalCoordinates(local_image_coords);
        end

%         function RemoveThisMarker(obj, marker)
% %             for index = 1: length(obj.MarkerPoints)
% %                 indexed_marker = obj.MarkerPoints(index);
% %                 if indexed_marker == marker
% %                     if (marker == obj.CurrentlyHighlightedMarker)
% %                         obj.CurrentlyHighlightedMarker = [];
% %                     end
% %                     obj.MarkerPoints(index) = [];
% %                     return;
% %                 end
% %             end
%         end
        
%         function DeleteHighlightedMarker(obj)
% %             if ~isempty(obj.CurrentlyHighlightedMarker)
% %                 obj.CurrentlyHighlightedMarker.DeleteMarker;
% %             end
%         end
%         
%         function ChangeCurrentColour(obj, new_colour)
% %             obj.CurrentColour = new_colour;
%         end
%         
%         function AddPointToMarkerImage(obj, marker_position, colour)
%             obj.LockCallback = true;
% %             coords = obj.GetImageCoordinates(marker_position);
% %             
% %             if obj.MarkerPointImage.ChangeMarkerPoint(coords, colour)
% %                 obj.MarkerImageHasChanged = true;
% %             end
%             
%             obj.LockCallback = false;
%         end
%         
%         % Find the image slice containing the last marker
%         function GotoPreviousMarker(obj)
% %             maximum_skip = obj.ViewerPanel.SliceSkip;
% %             orientation = obj.ViewerPanel.Orientation;
% %             current_coordinate = obj.ViewerPanel.SliceNumber(orientation);
% %             index_of_nearest_marker = obj.MarkerPointImage.GetIndexOfPreviousMarker(current_coordinate, maximum_skip, orientation);
% %             obj.ViewerPanel.SliceNumber(orientation) = index_of_nearest_marker;
%         end
%         
% %         function GotoNextMarker(obj)
% %             maximum_skip = obj.ViewerPanel.SliceSkip;
% %             orientation = obj.ViewerPanel.Orientation;
% %             current_coordinate = obj.ViewerPanel.SliceNumber(orientation);
% %             index_of_nearest_marker =  obj.MarkerPointImage.GetIndexOfNextMarker(current_coordinate, maximum_skip, orientation);            
% %             obj.ViewerPanel.SliceNumber(orientation) = index_of_nearest_marker;
% %         end
%         
% %         function GotoNearestMarker(obj)
% %             orientation = obj.ViewerPanel.Orientation;
% %             current_coordinate = obj.ViewerPanel.SliceNumber(orientation);
% %             index_of_nearest_marker = obj.MarkerPointImage.GetIndexOfNearestMarker(current_coordinate, orientation);
% %             obj.ViewerPanel.SliceNumber(orientation) = index_of_nearest_marker;
% %         end
% %         
% %         function GotoFirstMarker(obj)
% %             orientation = obj.ViewerPanel.Orientation;
% %             index_of_nearest_marker = obj.MarkerPointImage.GetIndexOfFirstMarker(orientation);
% %             obj.ViewerPanel.SliceNumber(orientation) = index_of_nearest_marker;
% %         end
% %         
% %         function GotoLastMarker(obj)
% %             orientation = obj.ViewerPanel.Orientation;
% %             index_of_nearest_marker = obj.MarkerPointImage.GetIndexOfLastMarker(orientation);
% %             obj.ViewerPanel.SliceNumber(orientation) = index_of_nearest_marker;
% %         end
% %         
%         function MarkerPointsHaveBeenSaved(obj)
%             obj.MarkerImageHasChanged = false;
%         end
%         
% %         function marker_image = GetMarkerImage(obj)
% %             marker_image = obj.MarkerPointImage.GetMarkerImage;
% %         end
% 
%     end
% 
%     methods (Access = private)
%         function ConvertMarkerImageToPoints(obj, slice_number, dimension)
%             if obj.MarkerPointImage.MarkerImageExists
%                 obj.Orientation = dimension;
%                 obj.SliceNumber = slice_number;
%                 
%                 [slice_markers, slice_size] = obj.MarkerPointImage.GetMarkersFromImage(slice_number, dimension);
%                 
%                 obj.CoordinateLimits = slice_size;
%                 
%                 for marker_s = slice_markers
%                     marker = marker_s{1};
%                     obj.NewMarker([marker.x, marker.y], marker.colour);
%                 end
%             end
%         end
%                 
%         function new_marker = NewMarker(obj, coords, colour)
%             new_marker = PTKMarkerPoint(coords, obj.AxesHandle, colour, obj, obj.CoordinateLimits);
%             
%             if isempty(obj.MarkerPoints)
%                 obj.MarkerPoints = new_marker;
%             else
%                 obj.MarkerPoints(end+1) = new_marker;
%             end
%             
%             if (obj.ShowTextLabels)
%                 new_marker.AddTextLabel;
%             end
%         end
%         
%         function ShowAllTextLabels(obj)
%             for marker = obj.MarkerPoints
%                 marker.AddTextLabel;
%             end
%         end
% 
%         function HideAllTextLabels(obj)
%             for marker = obj.MarkerPoints
%                 marker.RemoveTextLabel;
%             end
%         end
%         
%         function HighlightNone(obj)
%             if ~isempty(obj.CurrentlyHighlightedMarker)
%                 obj.CurrentlyHighlightedMarker.HighlightOff;
%                 obj.CurrentlyHighlightedMarker = [];
%             end
%         end
%         
%         function HighlightMarker(obj, marker)
%             if isempty(obj.CurrentlyHighlightedMarker) || (obj.CurrentlyHighlightedMarker ~= marker)
%                 obj.HighlightNone;
%                 marker.Highlight;
%                 obj.CurrentlyHighlightedMarker = marker;
%             end
%         end
%         
%         function closest_marker = GetMarkerForThisPoint(obj, coords, desired_colour)
%             [closest_marker, closest_distance] = obj.GetNearestMarker(coords, desired_colour);
%             if closest_distance > obj.ClosestDistanceForReplaceMarker
%                 closest_marker = [];
%             end
%         end
%         
%         function [closest_point, closest_distance] = GetNearestMarker(obj, coords, desired_colour)
%             closest_point = [];
%             closest_distance = [];
%             for marker = obj.MarkerPoints
%                 if isempty(desired_colour) || (desired_colour == marker.Colour)
%                     point_position = marker.GetPosition;
%                     distance = sum(abs(coords - point_position)); % Cityblock distance
%                     if isempty(closest_distance) || (distance < closest_distance)
%                         closest_distance = distance;
%                         closest_point = marker;
%                     end
%                 end
%             end
%         end
        
%         function RemoveAllPoints(obj)
%             obj.CurrentlyHighlightedMarker = [];
%             for marker = obj.MarkerPoints
%                 marker.RemoveGraphic;
%             end
%             obj.MarkerPoints = [];
%         end

%         function gaussian_se = CreateGaussianSE(obj, size)
%             gaussian_raw = zeros([31, 31, 31]);
%             gaussian_raw(16, 16) = 1;
%             gaussian_image = PTKImage(gaussian_raw);
%             obj.GaussianImage = PTKGaussianFilter(gaussian_image, 7);
%         end
        
        function CreateEditedImage(obj)
%             obj.DTImage = obj.ViewerPanel.OverlayImage.BlankCopy;
%             im = obj.ViewerPanel.OverlayImage.BlankCopy;
%             obj.DTImage.ChangeRawImage(bwdist(obj.ViewerPanel.OverlayImage.RawImage > 0));
%            
%             
%             gaussian_raw = zeros([31, 31, 31]);
%             gaussian_raw(16, 16) = 1;
%             gaussian_image = PTKImage(gaussian_raw);
%             obj.GaussianImage = PTKGaussianFilter(gaussian_image, 7);
        end
        
    end
end

