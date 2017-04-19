classdef GemMarkerPointImage < CoreBaseClass
    % GemMarkerPointImage. Part of the gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %     GemMarkerPointImage stores the underlying image which represents marker
    %     points. It abstracts the storage of the marker image away from the
    %     interactive creation and use of marker points in the MimViewerPanel.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    events
        MarkerImageHasChanged
    end
    
    properties (SetAccess = private)
        MarkerList
    end
    
    methods
        function obj = GemMarkerPointImage(marker_list)
            % The marker list must be created here, not in the properties section, to
            % prevent Matlab creating a circular dependency (see Matlab solution 1-6K9BQ7)
            % Also note that theis will trigger the above pointer change callback, which
            % will set up the pixel data change callback
            if nargin > 0
                obj.MarkerList = marker_list;
            else
                obj.MarkerList = zeros(0, 4);
            end
        end
        
        function ClearMarkers(obj)
            obj.MarkerList = zeros(0, 4);
            obj.NotifyMarkerImageChanged();
        end
        
        function image_to_save = GetImageToSave(obj, template)
            image_to_save = obj;
        end
        
        function ConvertImageToMarkers(obj, marker_image)
            indices = find(marker_image.RawImage > 0);
            indices_global = marker_image.LocalToGlobalIndices(indices);
            [i, j, k] = marker_image.GlobalIndicesToGlobalCoordinates(indices_global);
            
            obj.MarkerList = zeros(0, 4);
            for index = 1 : numel(indices)
                obj.MarkerList(end + 1, :) = [i(index), j(index), k(index), double(marker_image.RawImage(indices(index)))];
            end
        end
        
        function marker_image = ConvertMarkersToImage(obj, template)
            marker_image = template.BlankCopy();
            marker_image_raw = zeros(marker_image.ImageSize, 'uint8');
            marker_image.ChangeRawImage(marker_image_raw);
            for index = 1 : size(obj.MarkerList, 1)
                marker_image.SetVoxelToThis(obj.MarkerList(index, 1:3), obj.MarkerList(index, 4))
            end
        end
        
        function ChangeMarkerPoint(obj, local_coords, colour, template)
            global_coords = template.LocalToGlobalCoordinates(local_coords);
            global_coords = obj.BoundCoordsInImage(template, global_coords);

            list_indices = find(ismember(round(obj.MarkerList(:, 1:3)), global_coords,'rows'));
            
            if isempty(list_indices)
                % No existing marker
                if colour ~= 0
                    obj.MarkerList(end + 1, :) = [global_coords, colour];
                    obj.NotifyMarkerImageChanged();
                end
                
            elseif numel(list_indices) > 2
                % Multiple markers found at this point - replace with a
                % single marker
                
                % Remove all existing markers
                obj.MarkerList(list_indices, :) = [];
                
                if colour ~= 0
                    % Add a single marker with the new colour
                    obj.MarkerList(end + 1, :) = [global_coords, colour];
                end
                obj.NotifyMarkerImageChanged();
                
            else
                if colour == 0
                    % Remove existing marker
                    obj.MarkerList(list_indices, :) = [];
                    obj.NotifyMarkerImageChanged();
                else
                    % Replace marker colour
                    if obj.MarkerList(list_indices, 4) ~= colour
                        obj.MarkerList(list_indices, :) = [global_coords, colour];
                        obj.NotifyMarkerImageChanged();
                    end
                end
            end
        end
        
        function BackgroundImageChanged(obj, template)
        end
        
        function LoadMarkers(obj, markers)
            if isempty(markers)
                obj.MarkerList = zeros(0, 4);
            else
                if isa(markers, 'PTKImage')
                    obj.MarkerList = zeros(0, 4);
                    obj.ConvertImageToMarkers(markers);
                else
                    if isa(markers, 'GemMarkerPointImage')
                        obj.MarkerList = markers.MarkerList;
                    end
                end
            end
            obj.NotifyMarkerImageChanged();
        end
        
        function SetBlankMarkerImage(obj, template)
            obj.MarkerList = zeros(0, 4);
            obj.NotifyMarkerImageChanged();
        end
        
        function index_of_nearest_marker = GetIndexOfPreviousMarker(obj, current_coordinate_global, maximum_skip, orientation)
            markers = obj.MarkerList(obj.MarkerList(:, orientation) < current_coordinate_global, :);
            
            if isempty(markers)
                index_of_nearest_marker = max(1, current_coordinate_global - maximum_skip);
            else
                [~, index] = max(markers(:, orientation));
                index_of_nearest_marker = markers(index, orientation);                
            end
        end
        
        function index_of_nearest_marker = GetIndexOfNextMarker(obj, current_coordinate_global, maximum_skip, orientation)
            markers = obj.MarkerList(obj.MarkerList(:, orientation) > current_coordinate_global, :);
            
            if isempty(markers)
                index_of_nearest_marker = current_coordinate_global + maximum_skip;
            else
                [~, index] = min(markers(:, orientation));
                index_of_nearest_marker = markers(index, orientation);                
            end
        end
        
        function index_of_nearest_marker = GetIndexOfNearestMarker(obj, current_coordinate_global, orientation)
            if isempty(obj.MarkerList)
                index_of_nearest_marker = 1;
            else
                difference = abs(current_coordinate_global - obj.MarkerList(:, orientation));
                [~, index] = min(difference);
                index_of_nearest_marker = obj.MarkerList(index, orientation);
            end
        end

        function index_of_nearest_marker = GetIndexOfFirstMarker(obj, orientation)
            if isempty(obj.MarkerList)
                index_of_nearest_marker = 1;
            else
                [~, index] = min(obj.MarkerList(:, orientation));
                index_of_nearest_marker = obj.MarkerList(index, orientation);
            end
        end
        
        function index_of_nearest_marker = GetIndexOfLastMarker(obj, orientation)
            if isempty(obj.MarkerList)
                index_of_nearest_marker = 1;
            else
                [~, index] = max(obj.MarkerList(:, orientation));
                index_of_nearest_marker = obj.MarkerList(index, orientation);
            end
        end
    end
    
    methods (Access = private)
        
        function global_coords = BoundCoordsInImage(~, template_image, global_coords)
            global_coords = max(1, global_coords);
            full_image_size = template_image.OriginalImageSize;
            global_coords(1) = min(global_coords(1), full_image_size(1));
            global_coords(2) = min(global_coords(2), full_image_size(2));
            global_coords(3) = min(global_coords(3), full_image_size(3));
        end
        
        function NotifyMarkerImageChanged(obj)
            notify(obj, 'MarkerImageHasChanged');
        end
    end
end

