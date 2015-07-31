classdef PTKMatNatDatabaseSeries < handle
    % PTKMatNatDatabaseSeries.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
        function obj = PTKMatNatDatabaseSeries(series_id, single_image_metainfo, number_of_images)
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