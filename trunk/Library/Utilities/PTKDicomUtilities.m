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
        function is_dicom = PTKIsDicom(file_path, file_name)
            is_dicom = isdicom(fullfile(file_path, file_name));
        end
        
        % Reads in Dicom metadata from the specified file
        function metadata = ReadMetadata(file_path, file_name, reporting)
            try
                metadata = dicominfo(fullfile(file_path, file_name));
            catch exception
                reporting.Error('PTKDicomUtilities:MetaDataReadFail', ['Could not read metadata from the Dicom file ' file_name '. Error:' exception.message]);
            end
        end

        % Reads in Dicom image data from the specified metadata
        function image_data = ReadDicomFileFromMetadata(metadata, reporting)
            try
                image_data = dicomread(metadata);
            catch exception
                reporting.Error('PTKDicomUtilities:DicomReadError', ['Rrror while reading the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        % Reads in Dicom image data from the specified metadata. The image data
        % is stored directly into the RawImage matrix of a PTKWrapper object
        function ReadDicomFileIntoWrapperFromMetadata(metadata, image_wrapper, slice_index, reporting)
            try
                image_wrapper.RawImage(:, :, slice_index) = dicomread(metadata);
            catch exception
                reporting.Error('PTKDicomUtilities:DicomReadError', ['Error while reading the Dicom file ' file_name '. Error:' exception.message]);
            end
        end
        
        % Returns true if three images lie approximately on a straight line (determined
        % by the coordinates in the ImagePositionPatient Dicom tags)
        function match = AreImageLocationsConsistent(first_metadata, second_metadata, third_metadata)
            
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
                scale_2 = abs(direction_vector_1(scale_index_2)/direction_vector_2(scale_index_2));
            else
                scale_1 = abs(direction_vector_2(scale_index_1)/direction_vector_1(scale_index_1));
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
    end
end

