classdef PTKTestUtilities
    % PTKTestUtilities. Utility functions related to testing
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods (Static)

        function metadata = CreateMetaData(name, patient_id, study_uid, modality, series_description, study_description, date)
            metadata = [];
            metadata.PatientName.FamilyName = name;
            metadata.PatientId = patient_id;
            metadata.StudyInstanceUID = study_uid;
            metadata.Modality = modality;
            metadata.StudyDescription = study_description;
            metadata.SeriesDescription = series_description;
            metadata.AcquisitionDate = date;
        end
        
    end
end

