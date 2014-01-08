function single_image_info = PTKGetSingleImageInfo(file_path, file_name, tags_to_get, reporting)
    % PTKGetDicomSeries. Populates a PTKSingleImageMetaInfo object with meta
    %     information derived from an image file
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    if nargin < 4
        reporting = PTKReportingDefault;
    end

    if isempty(tags_to_get)
        tags_to_get = PTKDicomDictionary.GroupingTagsDictionary(false);
    end

    try
        header = PTKReadDicomTags(file_path, file_name, tags_to_get, reporting);
    catch ex
        header = dicominfo(fullfile(file_path, file_name));
    end
    
    if isempty(header)
        % This does not appear to be a Dicom file
        [image_type, principal_filename, secondary_filenames] = PTKDiskUtilities.GuessFileType(next_filename.Path, next_filename.Name, [], obj.Reporting);
        
        modality = [];
        file_name = principal_filename;
        patient_id = principal_filename;
        study_uid = principal_filename;
        series_uid = principal_filename;
        image_uid = principal_filename;
        patient_name = principal_filename;
        study_description = principal_filename;
        series_description = principal_filename;
        
    else
        image_type = PTKImageFileFormat.Dicom;
        
        modality = SetFromHeader(header, 'Modality', []);
        patient_id = SetFromHeader(header, 'PatientID', []);
        study_uid = SetFromHeader(header, 'StudyInstanceUID', []);
        series_uid = SetFromHeader(header, 'SeriesInstanceUID', []);
        image_uid = SetFromHeader(header, 'SOPInstanceUID', []);
        patient_name = SetFromHeader(header, 'PatientName', []);
        study_description = SetFromHeader(header, 'StudyDescription', []);
        series_description = SetFromHeader(header, 'SeriesDescription', []);
        date = SetFromHeader(header, 'SeriesDate', []);
        time = SetFromHeader(header, 'SeriesTime', []);
        
    end
        
    single_image_info = PTKSingleImageMetaInfo(file_path, file_name, image_type, modality, date, time, ...
        patient_id, study_uid, series_uid, image_uid, ...
        patient_name, study_description, series_description);
end

function result = SetFromHeader(header, field_name, default)
    if isfield(header, field_name)
        result = header.(field_name);
    else
        result = default;
    end
end
