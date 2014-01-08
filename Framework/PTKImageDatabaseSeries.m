classdef PTKImageDatabaseSeries < handle
    % PTKImageDatabaseSeries.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    
    properties (SetAccess = private)
        Name
        StudyName
        ImageMap
        Modality
        Date
        Time
        SeriesUid
        PatientId
    end
    
    methods
        function obj = PTKImageDatabaseSeries(series_name, study_name, modality, date, time, series_uid, patient_id)
            if nargin > 0
                obj.Name = series_name;
                obj.StudyName = study_name;
                obj.Modality = modality;
                obj.Date = date;
                obj.Time = time;
                obj.SeriesUid = series_uid;
                obj.PatientId = patient_id;
                
                obj.ImageMap = containers.Map;
            end
        end
        
        function AddImage(obj, single_image_metainfo)
            image_uid = single_image_metainfo.ImageUid;
            obj.ImageMap(image_uid) = single_image_metainfo;
        end
        
        function num_images = NumberOfImages(obj)
            num_images = obj.ImageMap.Count;
        end
        
        function image_info = GetImageInfo(obj)
            image_infos = obj.ImageMap.values;
            filenames = [];
            for image_index = 1 : numel(image_infos);
                single_image_info = image_infos{image_index};
                filenames{end + 1} = PTKFilename(single_image_info.ImagePath, single_image_info.ImageFilename);
            end
            path = image_infos{1}.ImagePath;
            image_type = image_infos{1}.ImageFileFormat;
            uid = obj.SeriesUid;
            study_uid = image_infos{1}.StudyUid;
            modality = obj.Modality;
            image_info = PTKImageInfo(path, filenames, image_type, uid, study_uid, modality);
        end
        
    end
end