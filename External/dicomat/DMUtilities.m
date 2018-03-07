classdef DMUtilities
    % DMUtilities. Utility functions related to Dicom files
    %
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %    
    
    methods (Static)

        function is_dicom = IsDicom(file_path, file_name)
            % Returns true if this is a Dicom file
    
            if strcmp(file_name, 'DICOMDIR')
                is_dicom = false;
                return
            end
            
            full_file_name = [file_path, filesep, file_name];
            
            is_dicom = DMFallbackDicomLibrary.getLibrary.isdicom(full_file_name);
        end
        
        function dicom_series_uid = GetDicomSeriesUid(fileName, dictionary)
            % Gets the series UID for a Dicom file
            
            if isempty(dictionary)
                dictionary = DMDicomDictionary.GroupingDictionary;
            end
            
            header = DMFallbackDicomLibrary.getLibrary.dicominfo(fileName, dictionary);
            
            if isempty(header)
                dicom_series_uid = [];
            else
                % If no SeriesInstanceUID tag then this is not a valid Dicom image (it
                % might be a DICOMDIR)
                if isfield(header, 'SeriesInstanceUID')
                    dicom_series_uid = header.SeriesInstanceUID;
                else
                    dicom_series_uid = [];
                end
            end
        end
        
        function metadata = ReadMetadata(fileName, dictionary, reporting)
            % Reads in Dicom metadata from the specified file
            try
                metadata = DMFallbackDicomLibrary.getLibrary.dicominfo(fileName, dictionary);
            catch exception
                reporting.Error('DMUtilities:MetaDataReadFail', ['Could not read metadata from the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        function metadata = ReadGroupingMetadata(fileName, reporting)
            % Reads in Dicom metadata from the specified file
            try
                metadata = DMFallbackDicomLibrary.getLibrary.dicominfo(fileName, DMDicomDictionary.GroupingDictionary);
            catch exception
                reporting.Error('DMUtilities:MetaDataReadFail', ['Could not read metadata from the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        function metadata = ReadEssentialMetadata(fileName, reporting)
            % Reads in Dicom metadata from the specified file
            try
                metadata = DMFallbackDicomLibrary.getLibrary.dicominfo(fileName);
            catch exception
                reporting.Error('DMUtilities:MetaDataReadFail', ['Could not read metadata from the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        function image_data = ReadDicomImageFromMetadata(metadata, reporting)
            % Reads in Dicom image data from the specified metadata

            try
                image_data = DMFallbackDicomLibrary.getLibrary.dicomread(metadata);
            catch exception
                reporting.Error('DMUtilities:DicomReadError', ['Error while reading the Dicom file. Error:' exception.message]);
            end
        end
        
        function ReadDicomImageIntoWrapperFromMetadata(metadata, image_wrapper, slice_index, reporting)
            % Reads in Dicom image data from the specified metadata. The image data
            % is stored directly into the RawImage matrix of a CoreWrapper object
            try
                image_wrapper.RawImage(:, :, slice_index, :) = DMFallbackDicomLibrary.getLibrary.dicomread(metadata);
                
            catch exception
                reporting.Error('DMUtilities:DicomReadError', ['Error while reading the Dicom file. Error:' exception.message]);
            end
        end
        
        function [name, short_name] = PatientNameToString(patient_name)
            if ischar(patient_name)
                name = patient_name;
            else
                name = '';
                short_name = '';
                if isstruct(patient_name)
                    name = DMUtilities.AddOptionalField(name, patient_name, 'FamilyName', false);
                    name = DMUtilities.AddOptionalField(name, patient_name, 'GivenName', false);
                    name = DMUtilities.AddOptionalField(name, patient_name, 'MiddleName', false);
                    name = DMUtilities.AddOptionalField(name, patient_name, 'NamePrefix', false);
                    name = DMUtilities.AddOptionalField(name, patient_name, 'NameSuffix', false);
                    
                    short_name = DMUtilities.AddOptionalField(short_name, patient_name, 'FamilyName', true);
                    short_name = DMUtilities.AddOptionalField(short_name, patient_name, 'GivenName', true);
                    short_name = DMUtilities.AddOptionalField(short_name, patient_name, 'MiddleName', true);
                    short_name = DMUtilities.AddOptionalField(short_name, patient_name, 'NamePrefix', true);
                    short_name = DMUtilities.AddOptionalField(short_name, patient_name, 'NameSuffix', true);
                end
            end
        end
        
        function new_text = AddOptionalField(text, struct_name, field_name, only_if_nonempty)
            if isempty(text) || ~only_if_nonempty
                new_text = text;
                if isfield(struct_name, field_name) && ~isempty(struct_name.(field_name))
                    if isempty(text)
                        prefix = '';
                    else
                        prefix = ', ';
                    end
                    new_text = [text, prefix, struct_name.(field_name)];
                end
            else
                new_text = text;
            end
        end
        
        function uid = GetIdentifierFromFilename(file_name)
            [~, uid, ~] = fileparts(file_name);
        end
        
        function dicom_filenames = RemoveNonDicomFiles(image_path, filenames)
            dicom_filenames = [];
            for index = 1 : length(filenames)
                if (DMUtilities.IsDicom(image_path, filenames{index}))
                    dicom_filenames{end + 1} = filenames{index};
                end
            end
        end
        
        function tag_string = ConvertTag32ToString(tag_32)
            group_value = floor(tag_32/65536);
            tag_value = mod(tag_32, 65536);
            tag_string = ['(' dec2hex(group_value, 4) ',' dec2hex(tag_value, 4) ')']; 
        end
        
        function tag_32 = ConvertStringToTag32(tag_string)
            group = tag_string(2:5);
            elem = tag_string(7:10);
            tag_32 = 65536*hex2dec(group) + hex2dec(elem);
        end
    end
end

