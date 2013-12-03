function PTKSaveImageAsDicom(image_data, path, filename, patient_name, is_secondary_capture, reporting)
    % PTKSaveImageAsDicom. Saves an image in DICOM format, using Matlab's image processing toolbox
    %
    %     Syntax
    %     ------
    %
    %         PTKSaveImageAsDicom(image_data, path, filename, patient_name, is_secondary_capture, reporting)
    %
    %             image_data      is a PTKImage (or PTKDicomImage) class containing the image
    %                             to be saved
    %             path, filename  specify the location to save the DICOM data. One 2D file
    %                             will be created for each image slice in the z direction. 
    %                             Each file is numbered, starting from 0.
    %                             So if filename is 'MyImage.DCM' then the files will be
    %                             'MyImage0.DCM', 'MyImage1.DCM', etc.
    %             patient_name    specifies the patient name to be stored in the image (only
    %                             used when there is no metadata available in the image)
    %             is_secondary_capture  should be set to true when the image is derived
    %                             (e.g. a segmentation), and should be set to false when the 
    %                             pixel data is unaltered from the original
    %                             image (except for cropping or reordering axes)
    %             reporting       A PTKReporting or implementor of the same interface,
    %                             for error and progress reporting. Create a PTKReporting
    %                             with no arguments to hide all reporting
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
   
    
    % Verify that the image is of the correct class
    if ~isa(image_data, 'PTKImage')
        reporting.Error('PTKSaveImageAsDicom:InputMustBePTKImage', 'Requires a PTKImage as input');
    end
    
    % Show a progress dialog
    if exist('reporting', 'var')
        reporting.ShowProgress('Saving DICOM images');
    end
    
    orientation = PTKImageCoordinateUtilities.ChooseOrientation(image_data.VoxelSize);
    
    
    full_filename = fullfile(path, filename);
    [filename_pathstr, filename_name, filename_ext] = fileparts(full_filename);

    slice_spacing = image_data.VoxelSize(3);
    pixel_spacing = image_data.VoxelSize(1:2);

    % Retrieve oiginal DICOM metadata from the image - note this may be empty if
    % the image was created from a non-DICOM image
    original_metadata = [];
    if isa(image_data, 'PTKDicomImage')
        original_metadata = image_data.MetaHeader; % Note the metadata may be empty
        study_uid = image_data.StudyUid;
    else
        study_uid = dicomuid;
    end
            
    % If we are saving a greayscale image, we preserve the metadata.
    % If we saving a secondary capture (i.e. a derived image such as a
    % segmentation) then we only preserve selected tags from the metadata.
    if is_secondary_capture
        metadata = [];
        metadata.Modality = 'OT';
        metadata.SeriesDescription = [PTKSoftwareInfo.DicomName ' : ' image_data.Title];
    else
        metadata = original_metadata;
        metadata = CopyField('Modality', metadata, original_metadata, image_data.Modality);
        metadata = CopyField('SeriesDescription', metadata, original_metadata, 'Original Image');
    end
    
    % There are certain tags we must change to ensure our series is grouped with
    % the original data
    metadata.SeriesInstanceUID = dicomuid; % MUST be unique for our series
    metadata.SecondaryCaptureDeviceManufacturer = PTKSoftwareInfo.DicomManufacturer;
    metadata.SecondaryCaptureDeviceManufacturerModelName = PTKSoftwareInfo.DicomName;
    metadata.SecondaryCaptureDeviceSoftwareVersion = PTKSoftwareInfo.DicomVersion;
    metadata.SeriesNumber = []; % SeriesNumber (unlike SeriesInstanceUID) is purely descriptive. Since there is no way of guaranteeing uniqueness, it is better not to set it then to set it to a value like 1 which may already be used
    
    metadata.PatientPosition = 'FFS';
    metadata.ImageType = 'ORIGINAL\PRIMARY\AXIAL';    
    metadata.SliceThickness = slice_spacing;
    metadata.SpacingBetweenSlices = slice_spacing;
    metadata.ImageOrientationPatient = [1 0 0 0 1 0]';
    metadata.PixelSpacing = pixel_spacing';

    metadata = CopyField('StudyInstanceUID', metadata, original_metadata, study_uid);
    metadata = CopyField('StudyID', metadata, original_metadata, []);
    metadata = CopyField('StudyDate', metadata, original_metadata, []);
    metadata = CopyField('StudyTime', metadata, original_metadata, []);
    
    default_study_description = PTKSoftwareInfo.DicomStudyDescription;
    metadata = CopyField('StudyDescription', metadata, original_metadata, default_study_description);

    metadata = CopyField('PatientName', metadata, original_metadata, patient_name);
    metadata = CopyField('PatientID', metadata, original_metadata, []);
    metadata = CopyField('IssuerOfPatientID', metadata, original_metadata, []);
    metadata = CopyField('PatientSex', metadata, original_metadata, []);
    metadata = CopyField('PatientAge', metadata, original_metadata, []);
    metadata = CopyField('PatientBirthDate', metadata, original_metadata, []);
    

    metadata = CopyField('AcquisitionDate', metadata, original_metadata, []);
    metadata = CopyField('AcquisitionTime', metadata, original_metadata, []);

    metadata = CopyField('Manufacturer', metadata, original_metadata, []);
    metadata = CopyField('InstitutionName', metadata, original_metadata, []);
    metadata = CopyField('ReferringPhysicianName', metadata, original_metadata, []);
    metadata = CopyField('OperatorName', metadata, original_metadata, []);
    metadata = CopyField('ManufacturerModelName', metadata, original_metadata, []);
    metadata = CopyField('ReferencedImageSequence', metadata, original_metadata, []);
    
    if strcmp(metadata, 'CT')
        metadata = CopyField('RescaleIntercept', metadata, original_metadata, -1024);
        metadata = CopyField('RescaleSlope', metadata, original_metadata, 1);
    end
    
    num_slices = image_data.ImageSize(orientation);
    for slice_index = 1 : num_slices
        if exist('reporting', 'var')
            reporting.UpdateProgressValue(round(100*(slice_index-1)/num_slices));
        end

        global_coords_slice = [1, 1, 1];
        global_coords_slice(orientation) = slice_index;
        [ic, jc, kc] = image_data.GlobalCoordinatesToCoordinatesMm(global_coords_slice);
        [ptk_x, ptk_y, ptk_z] = PTKImageCoordinateUtilities.CoordinatesMmToPTKCoordinates(ic, jc, kc);
        dicom_coordinates = PTKImageCoordinateUtilities.ConvertFromPTKCoordinates([ptk_x, ptk_y, ptk_z], PTKCoordinateSystem.Dicom, image_data);
        
        switch orientation
            case PTKImageOrientation.Axial
                slice_data = squeeze(image_data.RawImage(:, :, slice_index));
            case PTKImageOrientation.Coronal
                slice_data = squeeze(image_data.RawImage(slice_index, :, :))';
            case PTKImageOrientation.Sagittal
                slice_data = squeeze(image_data.RawImage(:, slice_index, :));
            
            otherwise
                reporting.Error('PTKSaveImageAsDicom:UnsupportedOrientation', ['The save image orientation ' char(orientation) ' is now known or unsupported.']);
        end
        
        if image_data.ImageType == PTKImageType.Colormap
            % Tags for RGB
            metadata.SamplesPerPixel = 3;
            metadata.PhotometricInterpretation = 'RGB';
            metadata.PlanarConfiguration = 0;
            metadata.NumberOfFrames = 1;
            metadata.BitsAllocated = 8;
            metadata.BitsStored = 8;
            metadata.HighBit = 7;
            [slice_data, ~] = PTKImageUtilities.GetImage(slice_data, [], PTKImageType.Colormap, [], []);
            
        else
            % Tags for CT greyscale image
            metadata.SamplesPerPixel = 1;
            metadata.PhotometricInterpretation = 'MONOCHROME2';
            metadata.BitsAllocated = 16;
            metadata.BitsStored = 16;
            metadata.HighBit = 15;
        end
                
        slice_location = double(dicom_coordinates);
        
        metadata.InstanceNumber = double(slice_index);
        metadata.ImagePositionPatient = slice_location;
        metadata.SliceLocation = slice_location(3);

        metadata.SOPInstanceUID = dicomuid; % MUST be unique for each image
        metadata.MediaStorageSOPInstanceUID = metadata.SOPInstanceUID;
        

        slice_filename = [filename_name, int2str(slice_index - 1)];
        full_filename = fullfile(filename_pathstr, [slice_filename, filename_ext]);
        
        status = dicomwrite(slice_data, full_filename, metadata);
        
        if ~IsStatusEmpty(status)
            reporting.ShowWarning('PTKSaveImageAsDicom:DicomWriteWarning', 'Dicomwrite returned a warning when saving the image', status);
        end
    end
    
    % Show a progress dialog
    if exist('reporting', 'var')
        reporting.CompleteProgress;
    end
    
end

function metadata = CopyField(tag_name, metadata, original_metadata, default)
    
    if isfield(original_metadata, tag_name)
        metadata.(tag_name) = original_metadata.(tag_name);
    else
        if ~isempty(default)
            metadata.(tag_name) = default;
        end
    end
end

function is_status_empty = IsStatusEmpty(status)
    is_status_empty = true;
    if isempty(status)
        return
    end
    
    is_status_empty = isempty(status.BadAttribute) && isempty(status.MissingCondition) && isempty(status.MissingData) && isempty(status.SuspectAttribute);
end