classdef MimMatNatDatabaseSeries < handle
    % MimMatNatDatabaseSeries.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %        

    properties (SetAccess = private)
        Name
        StudyName
        Modality
        Date
        Time
        SeriesUid
        StudyUid
        NumberOfImages
    end
    
    methods
        function obj = MimMatNatDatabaseSeries(series_id, single_image_metainfo, number_of_images)
            if nargin > 0
                obj.Name = single_image_metainfo.SeriesDescription;
                obj.StudyName = single_image_metainfo.StudyDescription;
                obj.Modality = single_image_metainfo.Modality;
                obj.Date = single_image_metainfo.Date;
                obj.Time = single_image_metainfo.Time;
                obj.SeriesUid = series_id;
                obj.StudyUid = single_image_metainfo.StudyUid;
                obj.NumberOfImages = number_of_images;
            end
        end
    end
end