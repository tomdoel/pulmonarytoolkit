classdef DMSingleImageMetaInfo
    % DMSingleImageMetaInfo. A structure for holding information related to a
    %     single image file
    %
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %
    
    properties
        ImagePath
        ImageFilename
        ImageFileFormat
        Modality
        Date
        Time
          
        PatientId
        StudyUid
        SeriesUid
        ImageUid
        
        PatientName
        StudyDescription
        SeriesDescription
        
        Version
    end
    
    methods
        function obj = DMSingleImageMetaInfo(path, filename, image_type, modality, date, time, ...
                patient_id, study_uid, series_uid, image_uid, ...
                patient_name, study_description, series_description)
            
            if nargin > 0
                obj.ImagePath = path;
                obj.ImageFilename = filename;
                obj.ImageFileFormat = image_type;
                obj.Modality = modality;
                obj.Date = date;
                obj.Time = time;
                                
                obj.PatientId = patient_id;
                obj.StudyUid = study_uid;
                obj.SeriesUid = series_uid;
                obj.ImageUid = image_uid;
                                
                obj.PatientName = patient_name;
                obj.StudyDescription = study_description;
                obj.SeriesDescription = series_description;
                obj.Version = 1;
            end
        end
    end
end