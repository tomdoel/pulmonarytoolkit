classdef TDMarkerPointImage < handle
    % TDMarkerPointImage. Part of the gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %     TDMarkerPointImage stores the underlying image which represents marker
    %     points. It abstracts the storage of the marker image away from the
    %     interactive creation and use of marker points in the TDViewerPanel.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        MarkerImage
    end
    
    methods
        function obj = TDMarkerPointImage
            obj.MarkerImage = TDImage;
        end
        
        function [slice_markers, slice_size] = GetMarkersFromImage(obj, slice_number, dimension)
            slice = obj.GetSlice(slice_number, dimension);
            slice_size = size(slice);
            
            [y, x] = find(slice);
            slice_markers = [];
            for index = 1 : numel(y)
                next_marker = [];
                next_marker.x = x(index);
                next_marker.y = y(index);
                next_marker.colour = slice(y(index), x(index));
                slice_markers{end + 1} = next_marker;
            end
        end
        
        function global_coords = LocalToGlobalCoordinates(obj, local_coords)
            global_coords = obj.MarkerImage.LocalToGlobalCoordinates(local_coords);
        end
        
        function image_has_changed = ChangeMarkerPoint(obj, local_coords, colour)
            global_coords = obj.MarkerImage.LocalToGlobalCoordinates(local_coords);
            global_coords = obj.MarkerImage.BoundCoordsInImage(global_coords);

            current_value = obj.MarkerImage.GetVoxel(global_coords);
            if (current_value ~= colour)
                obj.MarkerImage.SetVoxelToThis(global_coords, colour);
                image_has_changed = true;
            else
                image_has_changed = false;
            end
        end
        
        function ChangeMarkerSubImage(obj, new_image)
            obj.MarkerImage.ChangeSubImage(new_image);
        end
        
        function BackgroundImageChanged(obj, template)
            obj.MarkerImage = template;
            obj.MarkerImage.ChangeRawImage(zeros(template.ImageSize, 'uint8'));            
            obj.MarkerImage.ImageType = TDImageType.Colormap;
        end
        
        function index_of_nearest_marker = GetIndexOfPreviousMarker(obj, current_coordinate, maximum_skip, orientation)
            
            coordinate_range = [current_coordinate - maximum_skip, current_coordinate - 1];
            coordinate_range = max(1, coordinate_range);
            coordinate_range = coordinate_range(1) : coordinate_range(2);
            
            switch orientation
                case TDImageOrientation.Coronal
                    consider_image = obj.MarkerImage.RawImage(coordinate_range, :, :);
                case TDImageOrientation.Sagittal
                    consider_image = obj.MarkerImage.RawImage(:, coordinate_range, :);
                case TDImageOrientation.Axial
                    consider_image = obj.MarkerImage.RawImage(:, :, coordinate_range);
            end
            other_dimension = setxor([1 2 3], orientation);
            any_markers = any(any(consider_image, other_dimension(1)), other_dimension(2));
            any_markers = squeeze(any_markers);
            any_markers = any_markers(end:-1:1);
            index_of_nearest_marker = find(any_markers, 1, 'first');
            if isempty(index_of_nearest_marker)
                index_of_nearest_marker = max(1, current_coordinate - maximum_skip);
            else
                index_of_nearest_marker = current_coordinate - index_of_nearest_marker;
            end    
        end
        
        function index_of_nearest_marker = GetIndexOfNextMarker(obj, current_coordinate, maximum_skip, orientation)
            max_coordinate = obj.MarkerImage.ImageSize(orientation);
            coordinate_range = [current_coordinate + 1, current_coordinate + maximum_skip, current_coordinate];
            coordinate_range = min(max_coordinate, coordinate_range);
            coordinate_range = coordinate_range(1) : coordinate_range(2);
            switch orientation
                case TDImageOrientation.Coronal
                    consider_image = obj.MarkerImage.RawImage(coordinate_range, :, :);
                case TDImageOrientation.Sagittal
                    consider_image = obj.MarkerImage.RawImage(:, coordinate_range, :);
                case TDImageOrientation.Axial
                    consider_image = obj.MarkerImage.RawImage(:, :, coordinate_range);
            end
            other_dimension = setxor([1 2 3], orientation);
            any_markers = any(any(consider_image, other_dimension(1)), other_dimension(2));
            any_markers = squeeze(any_markers);
            index_of_nearest_marker = find(any_markers, 1, 'first');
            if isempty(index_of_nearest_marker)
                index_of_nearest_marker = min(max_coordinate, current_coordinate + maximum_skip);
            else
                index_of_nearest_marker = current_coordinate + index_of_nearest_marker;
            end
        end
        
        function index_of_nearest_marker = GetIndexOfNearestMarker(obj, current_coordinate, orientation)
            consider_image = obj.MarkerImage.RawImage;
            other_dimension = setxor([1 2 3], orientation);
            any_markers = any(any(consider_image, other_dimension(1)), other_dimension(2));
            any_markers = squeeze(any_markers);
            indices = find(any_markers);
            if isempty(indices)
                index_of_nearest_marker = 1;
            else
                relative_indices = indices - current_coordinate;
                [~, min_relative_index] = min(abs(relative_indices - 0.1));
                index_of_nearest_marker = relative_indices(min_relative_index) + current_coordinate;
            end
        end

        function index_of_nearest_marker = GetIndexOfFirstMarker(obj, orientation)
            consider_image = obj.MarkerImage.RawImage;
            other_dimension = setxor([1 2 3], orientation);
            any_markers = any(any(consider_image, other_dimension(1)), other_dimension(2));
            any_markers = squeeze(any_markers);
            indices = find(any_markers);
            if isempty(indices)
                index_of_nearest_marker = 1;
            else
                [~, index_of_nearest_marker] = min(indices);
                index_of_nearest_marker = indices(index_of_nearest_marker);
            end
        end
        
        function index_of_nearest_marker = GetIndexOfLastMarker(obj, orientation)
            consider_image = obj.MarkerImage.RawImage;
            max_coordinate = obj.MarkerImage.ImageSize(orientation);
            other_dimension = setxor([1 2 3], orientation);
            any_markers = any(any(consider_image, other_dimension(1)), other_dimension(2));
            any_markers = squeeze(any_markers);
            indices = find(any_markers);
            if isempty(indices)
                index_of_nearest_marker = max_coordinate;
            else
                [~, index_of_nearest_marker] = max(indices);
                index_of_nearest_marker = indices(index_of_nearest_marker);
            end
        end
        
        
        function image_exists = MarkerImageExists(obj)
            image_exists = obj.MarkerImage.ImageExists;
        end
        
        function marker_image = GetMarkerImage(obj)
            marker_image = obj.MarkerImage;
        end        
        
    end
    
    methods (Access = private)
        
        function slice = GetSlice(obj, slice_number, dimension)
            slice = obj.MarkerImage.GetSlice(slice_number, dimension);
            if (dimension == 1) || (dimension == 2)
                slice = slice'; 
            end
        end

        function SetSlice(obj, slice, slice_number, dimension)
            if (dimension == 1) || (dimension == 2)
                slice = slice';
            end
            obj.MarkerImage.ReplaceImageSlice(slice, slice_number, dimension);
        end
        
    end
    
end

