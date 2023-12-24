classdef MimMarkerList
    %MimMarkerList Used in storing marker points in the cache
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties
        MarkerList
        SeriesUid
    end
    
    methods
        function obj = MimMarkerList(marker_image, series_uid)
            obj.MarkerList = MimMarkerPoint.empty();
            if nargin > 0
                if ~isempty(marker_image)
                    markerList = marker_image.MarkerList;
                    for markerIndex = 1 : size(markerList, 1)
                        obj.MarkerList(end + 1) = MimMarkerPoint(markerList(markerIndex, 1), markerList(markerIndex, 2), markerList(markerIndex, 3), markerList(markerIndex, 4)); 
                    end
                end
                obj.SeriesUid = series_uid;
            end
        end
        
        function markerList = ConvertToMarkerList(obj)
            if isempty(obj.MarkerList)
                markerList = zeros(0, 4);
            else
                x = CoreContainerUtilities.GetMatrixOfPropertyValues(obj.MarkerList, 'X', -1);
                y = CoreContainerUtilities.GetMatrixOfPropertyValues(obj.MarkerList, 'Y', -1);
                z = CoreContainerUtilities.GetMatrixOfPropertyValues(obj.MarkerList, 'Z', -1);
                label = CoreContainerUtilities.GetMatrixOfPropertyValues(obj.MarkerList, 'Label', 0);
                markerList = [x', y', z', label'];
            end
        end
    end
end

