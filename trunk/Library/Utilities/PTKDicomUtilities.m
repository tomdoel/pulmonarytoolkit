classdef PTKDicomUtilities
    % PTKDicomUtilities. Utility functions related to Dicom files
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods (Static)

        % Returns true if this is a Dicom file
        function is_dicom = IsDicom(file_path, file_name)
    
            if strcmp(file_name, 'DICOMDIR')
                is_dicom = false;
                return
            end
            
            try
                is_dicom = PTKIsDicomFile(file_path, file_name);
            catch exception
                is_dicom = isdicom(fullfile(file_path, file_name));
            end
        end
        
        % Reads in Dicom metadata from the specified file
        function metadata = ReadMetadata(file_path, file_name, dictionary, reporting)
            try
                try
                    metadata = PTKReadDicomTags(file_path, file_name, dictionary, reporting);
                    metadata.Filename = [file_path, filesep, file_name];
                    
                catch exception
                    metadata = dicominfo(fullfile(file_path, file_name));
                end
            catch exception
                reporting.Error('PTKDicomUtilities:MetaDataReadFail', ['Could not read metadata from the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        % Reads in Dicom metadata from the specified file
        function metadata = ReadGroupingMetadata(file_path, file_name, reporting)
            try
                try
                    metadata = PTKReadDicomTags(file_path, file_name, PTKDicomDictionary.GroupingTagsDictionary(false), reporting);
                catch exception
                    metadata = dicominfo(fullfile(file_path, file_name));
                end
            catch exception
                reporting.Error('PTKDicomUtilities:MetaDataReadFail', ['Could not read metadata from the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        % Reads in Dicom metadata from the specified file
        function metadata = ReadEssentialMetadata(file_path, file_name, reporting)
            try
                try
                    metadata = PTKReadDicomTags(file_path, file_name, PTKDicomDictionary.EssentialTagsDictionary(false), reporting);
                    metadata.Filename = fullfile(file_path, file_name);
                    
                catch exception
                    metadata = dicominfo(fullfile(file_path, file_name));
                end
            catch exception
                reporting.Error('PTKDicomUtilities:MetaDataReadFail', ['Could not read metadata from the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        % Reads in Dicom image data from the specified metadata
        function image_data = ReadDicomImageFromMetadata(metadata, reporting)
            try
                try
                    [file_path, file_name] = PTKDiskUtilities.GetFullFileParts(metadata.Filename);
                    header = PTKReadDicomTags(file_path, file_name, PTKDicomDictionary.EssentialTagsDictionary(true), reporting);
                    image_data = header.PixelData;
                    
                catch exception
                    image_data = dicomread(metadata);
                end
                
            catch exception
                reporting.Error('PTKDicomUtilities:DicomReadError', ['Rrror while reading the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        % Reads in Dicom image data from the specified metadata. The image data
        % is stored directly into the RawImage matrix of a PTKWrapper object
        function ReadDicomImageIntoWrapperFromMetadata(metadata, image_wrapper, slice_index, reporting)
            try
                try
                    [file_path, file_name] = PTKDiskUtilities.GetFullFileParts(metadata.Filename);
                    header = PTKReadDicomTags(file_path, file_name, PTKDicomDictionary.EssentialTagsDictionary(true), reporting);
                    image_wrapper.RawImage(:, :, slice_index, :) = header.PixelData;
                    
                catch exception
                    image_wrapper.RawImage(:, :, slice_index, :) = dicomread(metadata);
                end
                
            catch exception
                reporting.Error('PTKDicomUtilities:DicomReadError', ['Error while reading the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        % Returns true if three images lie approximately on a straight line (determined
        % by the coordinates in the ImagePositionPatient Dicom tags)
        function match = AreImageLocationsConsistent(first_metadata, second_metadata, third_metadata)
            
            % If the ImagePositionPatient tag is not present, assume it is
            % consistent
            if (~isfield(first_metadata, 'ImagePositionPatient')) && (~isfield(second_metadata, 'ImagePositionPatient'))  && (~isfield(third_metadata, 'ImagePositionPatient'))
                match = true;
                return;
            end
            
            % First get the image position
            first_position = first_metadata.ImagePositionPatient;
            second_position = second_metadata.ImagePositionPatient;
            third_position = third_metadata.ImagePositionPatient;
            
            % Next, compute direction vectors between the points
            direction_vector_1 = second_position - first_position;
            direction_vector_2 = third_position - first_position;
            
            % Find a scaling between the direction vectors
            [max_1, scale_index_1] = max(abs(direction_vector_1));
            [max_2, scale_index_2] = max(abs(direction_vector_2));
            
            if max_1 > max_2
                scale_1 = 1;
                scale_2 = direction_vector_1(scale_index_2)/direction_vector_2(scale_index_2);
            else
                scale_1 = direction_vector_2(scale_index_1)/direction_vector_1(scale_index_1);
                scale_2 = 1;
            end
            
            % Scale
            scaled_direction_vector_1 = direction_vector_1*scale_1;
            scaled_direction_vector_2 = direction_vector_2*scale_2;
            
            % Find the maximum absolute difference between the normalised vectors
            difference = abs(scaled_direction_vector_2 - scaled_direction_vector_1);
            max_difference = max(difference);
            
            tolerance_mm = 10;
            match = max_difference <= tolerance_mm;
        end
        
        function [name, short_name] = PatientNameToString(patient_name)
            if ischar(patient_name)
                name = patient_name;
            else
                name = '';
                short_name = '';
                if isstruct(patient_name)
                    name = PTKDicomUtilities.AddOptionalField(name, patient_name, 'FamilyName', false);
                    name = PTKDicomUtilities.AddOptionalField(name, patient_name, 'GivenName', false);
                    name = PTKDicomUtilities.AddOptionalField(name, patient_name, 'MiddleName', false);
                    name = PTKDicomUtilities.AddOptionalField(name, patient_name, 'NamePrefix', false);
                    name = PTKDicomUtilities.AddOptionalField(name, patient_name, 'NameSuffix', false);
                    
                    short_name = PTKDicomUtilities.AddOptionalField(short_name, patient_name, 'FamilyName', true);
                    short_name = PTKDicomUtilities.AddOptionalField(short_name, patient_name, 'GivenName', true);
                    short_name = PTKDicomUtilities.AddOptionalField(short_name, patient_name, 'MiddleName', true);
                    short_name = PTKDicomUtilities.AddOptionalField(short_name, patient_name, 'NamePrefix', true);
                    short_name = PTKDicomUtilities.AddOptionalField(short_name, patient_name, 'NameSuffix', true);
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
    end
end

