function single_image_info = MimGetSingleImageInfo(file_path, file_name, file_format, tags_to_get, reporting)
    % Populate a DMSingleImageMetaInfo object with meta
    % information derived from an image file
    %
    % Syntax:
    %     single_image_info = MimGetSingleImageInfo(file_path, file_name, file_format, tags_to_get, reporting);
    %
    % Parameters:
    %     filepath: path where the image file is located
    %     filename: Filename for the image file in the filepath
    %     file_format (optional): an enum of type MimImageFileFormat, or
    %         set to [] to detect the file format automatically
    %     tags_to_get: the DICOM tages to read. Set to [] to use the default
    %         DMDicomDictionary.GroupingDictionary.
    %     reporting: an object implementing CoreReportingInterface
    %         for reporting progress and warnings
    %
    % Returns:
    %     single_image_info (DMSingleImageMetaInfo): structure containing metadata from 
    %         the image
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    if nargin < 4
        reporting = CoreReportingDefault();
    end

    if isempty(tags_to_get)
        tags_to_get = DMDicomDictionary.GroupingDictionary;
    end

    full_file_name = fullfile(file_path, file_name);
    
    % Attempt to load a Dicom header if the file format is Dicom or unknown
    header = [];
    if isempty(file_format) || CoreCompareUtilities.CompareEnumName(file_format, MimImageFileFormat.Dicom)
        try
            header = DMReadDicomTags(full_file_name, tags_to_get);
        catch ex %#ok<NASGU>
            try
                header = dicominfo(full_file_name);
            catch ex %#ok<NASGU>
                header = [];
            end
        end
    end
    
    if ~isempty(header)
        file_format = MimImageFileFormat.Dicom;

    else
        % This does not appear to be a Dicom file
        [file_format, principal_filename, secondary_filenames] = MimGuessFileType(file_path, file_name, [], reporting);
        
        % Set the filename to the principal file (i.e. the header)
        file_name = principal_filename{1};
        full_file_name = fullfile(file_path, principal_filename{1});
        
        % Try and load headers for other types
        if CoreCompareUtilities.CompareEnumName(file_format, MimImageFileFormat.Analyze)
            try
                header = hdr_read_header(full_file_name);
            catch ex %#ok<NASGU>
                header = [];
            end
        end
    end
    
    % Populate metadata from the header, with some sensible defaults
    modality = SetFromHeader(header, 'Modality', []);
    date = SetFromHeader(header, 'SeriesDate', []);
    time = SetFromHeader(header, 'SeriesTime', []);
    study_uid = SetFromHeader(header, 'StudyInstanceUID', []);
    filename_indentifier = DMUtilities.GetIdentifierFromFilename(file_name);
    series_uid_backup = [filename_indentifier '_' CoreSystemUtilities.StringToHash(full_file_name)];
    series_uid = SetFromHeader(header, 'SeriesInstanceUID', series_uid_backup);
    patient_visible_name_backup = filename_indentifier;
    patient_id = ValidateAndSetFromHeader(header, 'PatientID', series_uid);                
    image_uid = SetFromHeader(header, 'SOPInstanceUID', series_uid);
    backup_patient_name = [];
    backup_patient_name.FamilyName = patient_visible_name_backup;
    patient_name = ValidateAndSetFromHeader(header, 'PatientName', backup_patient_name);
    study_description = ValidateAndSetFromHeader(header, 'StudyDescription', []);
    series_description_backup = DMUtilities.GetIdentifierFromFilename(file_name);
    series_description = ValidateAndSetFromHeader(header, 'SeriesDescription', series_description_backup);    
    
    single_image_info = DMSingleImageMetaInfo(file_path, file_name, file_format, modality, date, time, ...
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

function result = ValidateAndSetFromHeader(header, field_name, default)
    if isfield(header, field_name)
        result = CoreTextUtilities.RemoveNonprintableCharactersAndStrip(header.(field_name));
        if isempty(result)
            result = default;
        end
    else
        result = default;
    end
end
