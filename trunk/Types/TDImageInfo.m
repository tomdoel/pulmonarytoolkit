classdef TDImageInfo
    % TDImageInfo. A structure for holding information related to images
    %
    %     TDImageInfo is used to specify data about the files that comprise a
    %     dataset. When importing new data, it is only necessary to specify the
    %     path, filenames and image type. When subsequently loading data,
    %     specifying the uids mean these don't have to be reloaded from the
    %     metadata.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties
        ImagePath
        ImageFilenames
        ImageFileFormat
        ImageUid
        StudyUid
        Modality
    end
    
    methods
        function obj = TDImageInfo(path, filenames, image_type, uid, study_uid, modality)
            obj.ImagePath = path;
            obj.ImageFilenames = filenames;
            obj.ImageFileFormat = image_type;
            obj.ImageUid = uid;
            obj.StudyUid = study_uid;
            obj.Modality = modality;
        end
    end
end

