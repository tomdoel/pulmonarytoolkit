classdef PTKSeriesDatabaseInfo
    % PTKSeriesDatabaseInfo. A structure for holding metadata for an image
    %     series
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties
        Modality
        PatientName
        PatientId
        Uid
        SeriesDescription
        StudyDescription
        NumOfImages
        Date
    end
    
    methods
        function obj = PTKSeriesDatabaseInfo(metadata, num_images)
            if nargin > 0
                obj.PatientName = metadata.PatientName.FamilyName;
                obj.PatientId = metadata.PatientId;
                obj.Uid = metadata.StudyInstanceUID;
                obj.Modality = metadata.Modality;
                obj.SeriesDescription = metadata.SeriesDescription;
                obj.StudyDescription = metadata.StudyDescription;
                obj.Date = metadata.AcquisitionDate;
                obj.NumOfImages = num_images;
            end
        end
    end
end

