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

    end
end

