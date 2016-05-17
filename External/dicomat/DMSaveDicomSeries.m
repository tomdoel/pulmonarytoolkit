function DMSaveDicomSeries(base_filename, ordered_image, dicom_coordinates_list, metadata, image_type, software_info, reporting)
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %

    metadata.SeriesInstanceUID = dicomuid; % MUST be unique for our series
    metadata.SecondaryCaptureDeviceManufacturer = software_info.DicomManufacturer;
    metadata.SecondaryCaptureDeviceID = software_info.DicomName;
    metadata.SecondaryCaptureDeviceManufacturerModelName = software_info.DicomName;
    metadata.SecondaryCaptureDeviceSoftwareVersion = software_info.DicomVersion;
    metadata.SeriesNumber = []; % SeriesNumber (unlike SeriesInstanceUID) is purely descriptive. Since there is no way of guaranteeing uniqueness, it is better not to set it then to set it to a value like 1 which may already be used

    if isequal(image_type, DMImageType.RGBLabel)
        % Tags for derived image
        metadata.ImageType = 'DERIVED\SECONDARY';
        metadata.Modality = 'OT';
        metadata.SOPClassUID = '1.2.840.10008.5.1.4.1.1.7'; % Secondary Capture Image Storage
        metadata.MediaStorageSOPClassUID = metadata.SOPClassUID;
        metadata.ConversionType = 'WSD'; % Workstation
        
        % Tags for RGB image
        metadata.SamplesPerPixel = 3;
        metadata.PhotometricInterpretation = 'RGB';
        metadata.PlanarConfiguration = 0;
        metadata.NumberOfFrames = 1;
        metadata.BitsAllocated = 8;
        metadata.BitsStored = 8;
        metadata.HighBit = 7;
        
    elseif isequal(image_type, DMImageType.MonoOriginal)
        % Tags for original image
        metadata.ImageType = 'ORIGINAL\PRIMARY';

        % Tags for greyscale image
        metadata.SamplesPerPixel = 1;
        metadata.PhotometricInterpretation = 'MONOCHROME2';
        metadata.BitsAllocated = 16;
        metadata.BitsStored = 16;
        metadata.HighBit = 15;
        
    else
        reporting.ShowWarning('DMSaveDicomSeries:UnknownImageTyoe', 'The specified image type was not recognised', []);
    end


    num_slices = size(ordered_image, 3);
    [filename_pathstr, filename_name, filename_ext] = fileparts(base_filename);
    
    % Save each slice as a separate image
    for slice_index = 1 : num_slices
        
        % Update progress
        if exist('reporting', 'var')
            reporting.UpdateProgressValue(round(100*(slice_index-1)/num_slices));
        end
        
        % Determine the slice filename
        slice_filename = [filename_name, int2str(slice_index - 1)];
        full_filename = fullfile(filename_pathstr, [slice_filename, filename_ext]);
        
        % Get the next image slice
        slice_data = ordered_image(:, :, slice_index);
        
        % For label images, convert to RGB
        if isequal(image_type, DMImageType.RGBLabel)
            [slice_data, ~] = CoreImageUtilities.GetLabeledImage(slice_data, []);
        end
        
        % The current image number. Although the Dicom standard does not guarantee
        % any interpretation of this, it is commonly taken to indicate image order
        metadata.InstanceNumber = double(slice_index);
        
        % The coordinates of the first voxel in the slice
        slice_location = double(dicom_coordinates_list(slice_index, :));
        metadata.ImagePositionPatient = slice_location;
        metadata.SliceLocation = slice_location(3);
        
        % Unique identifiers
        metadata.SOPInstanceUID = dicomuid; % MUST be unique for each image
        metadata.MediaStorageSOPInstanceUID = metadata.SOPInstanceUID; % MediaStorageSOPInstanceUID must be the same as the SOPInstanceUID
        
        % Write the slice
        status = dicomwrite(slice_data, full_filename, metadata, 'CreateMode', 'Copy');
        
        % Check the result of the writing operation
        if ~IsStatusEmpty(status)
            reporting.ShowWarning('DMSaveDicomSeries:DicomWriteWarning', 'Dicomwrite returned a warning when saving the image', status);
        end
    end
    
    % Signal progress completion
    if exist('reporting', 'var')
        reporting.CompleteProgress;
    end
    
end

function is_status_empty = IsStatusEmpty(status)
    is_status_empty = true;
    if isempty(status)
        return
    end
    
    is_status_empty = isempty(status.BadAttribute) && isempty(status.MissingCondition) && isempty(status.MissingData) && isempty(status.SuspectAttribute);
end