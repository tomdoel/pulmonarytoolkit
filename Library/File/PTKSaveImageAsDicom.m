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
    %             reporting       an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
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
    
    orientation = MimImageCoordinateUtilities.ChooseOrientation(image_data.VoxelSize);
    
    full_filename = fullfile(path, filename);


    % Retrieve oiginal DICOM metadata from the image - note this may be empty if
    % the image was created from a non-DICOM image
    original_metadata = [];
    if isa(image_data, 'PTKDicomImage')
        original_metadata = image_data.MetaHeader; % Note the metadata may be empty
        study_uid = image_data.StudyUid;
    else
        study_uid = dicomuid;
    end
            
    % If we are saving a greyscale image, we preserve the metadata.
    % If we saving a secondary capture (i.e. a derived image such as a
    % segmentation) then we only preserve selected tags from the metadata.
    if is_secondary_capture
        metadata = [];
        metadata.SeriesDescription = [PTKSoftwareInfo.DicomName ' : ' image_data.Title];
    else
        metadata = original_metadata;
        metadata = CopyField('Modality', metadata, original_metadata, image_data.Modality);
        metadata = CopyField('SeriesDescription', metadata, original_metadata, 'Original Image');
        metadata = CopyField('SOPClassUID', metadata, original_metadata, []);
    end
    
    
    switch orientation
        case PTKImageOrientation.Axial
            metadata.ImageOrientationPatient = [1 0 0 0 1 0]';
            slice_spacing = image_data.VoxelSize(3);
            pixel_spacing = image_data.VoxelSize(1:2);
            
        case PTKImageOrientation.Coronal
            metadata.ImageOrientationPatient = [1 0 0 0 0 -1]';
            slice_spacing = image_data.VoxelSize(1);
            pixel_spacing = image_data.VoxelSize([3,2]);
            
        case PTKImageOrientation.Sagittal
            metadata.ImageOrientationPatient = [0 1 0 0 0 -1]';
            slice_spacing = image_data.VoxelSize(2);
            pixel_spacing = image_data.VoxelSize([3,1]);
            
        otherwise
            reporting.Error('PTKSaveImageAsDicom:UnsupportedOrientation', ['The save image orientation ' char(orientation) ' is now known or unsupported.']);
    end
    
    metadata.SliceThickness = slice_spacing;
    metadata.SpacingBetweenSlices = slice_spacing;
    metadata.PixelSpacing = pixel_spacing';
    metadata = CopyField('PatientPosition', metadata, original_metadata, []);

    
    % There are certain tags we must change to ensure our series is grouped with
    % the original data
    metadata = CopyField('StudyInstanceUID', metadata, original_metadata, study_uid);
    metadata = CopyField('StudyID', metadata, original_metadata, []);
    metadata = CopyField('StudyDate', metadata, original_metadata, []);
    metadata = CopyField('StudyTime', metadata, original_metadata, []);
    metadata = CopyField('SpecificCharacterSet', metadata, original_metadata, []);
    
    default_study_description = PTKSoftwareInfo.DicomStudyDescription;
    metadata = CopyField('StudyDescription', metadata, original_metadata, default_study_description);

    metadata = CopyField('PatientName', metadata, original_metadata, patient_name);
    metadata = CopyField('PatientID', metadata, original_metadata, []);
    metadata = CopyField('IssuerOfPatientID', metadata, original_metadata, []);
    metadata = CopyField('PatientSex', metadata, original_metadata, []);
    metadata = CopyField('PatientAge', metadata, original_metadata, []);
    metadata = CopyField('PatientBirthDate', metadata, original_metadata, []);
    metadata = CopyField('AccessionNumber', metadata, original_metadata, []);

    metadata = CopyField('AcquisitionDate', metadata, original_metadata, []);
    metadata = CopyField('AcquisitionTime', metadata, original_metadata, []);

    metadata = CopyField('ContentDate', metadata, original_metadata, []);
    metadata = CopyField('ContentTime', metadata, original_metadata, []);
    
    metadata = CopyField('Manufacturer', metadata, original_metadata, []);
    metadata = CopyField('InstitutionName', metadata, original_metadata, []);
    metadata = CopyField('ReferringPhysicianName', metadata, original_metadata, []);
    metadata = CopyField('OperatorName', metadata, original_metadata, []);
    metadata = CopyField('ManufacturerModelName', metadata, original_metadata, []);
    metadata = CopyField('ReferencedImageSequence', metadata, original_metadata, []);
    
    if isfield(metadata, 'Modality') && strcmp(metadata.Modality, 'CT')
        metadata = CopyField('RescaleIntercept', metadata, original_metadata, -1024);
        metadata = CopyField('RescaleSlope', metadata, original_metadata, 1);
    end
    
    if image_data.ImageType == PTKImageType.Colormap
        image_type = DMImageType.RGBLabel;
    else
        image_type = DMImageType.MonoOriginal;
    end
    
    reordered_image = ReorderImage(image_data, orientation, reporting);
    dicom_coordinates_list = ComputeDicomSliceCoordinates(image_data, orientation);
    
    DMSaveDicomSeries(full_filename, reordered_image, dicom_coordinates_list, metadata, image_type, PTKSoftwareInfo, reporting);
end

function reordered_image = ReorderImage(image_data, orientation, reporting)
    switch orientation
        case PTKImageOrientation.Axial
            saved_dimension_order = [1, 2, 3];
        case PTKImageOrientation.Coronal
            saved_dimension_order = [3, 2, 1];
        case PTKImageOrientation.Sagittal
            saved_dimension_order = [3, 1, 2];            
        otherwise
            reporting.Error('PTKSaveImageAsDicom:UnsupportedOrientation', ['The save image orientation ' char(orientation) ' is not known or unsupported.']);
    end
    
    reordered_image = permute(image_data.RawImage, saved_dimension_order);
end

function dicom_coordinates_list = ComputeDicomSliceCoordinates(image_data, orientation)
    num_slices = image_data.ImageSize(orientation);
    local_coordinates_list = ones(num_slices, 3);
    local_coordinates_list(:, orientation) = (1 : num_slices)';
    global_image_coords = image_data.LocalToGlobalCoordinates(local_coordinates_list);
    [x_mm, y_mm, z_mm] = image_data.GlobalCoordinatesToCoordinatesMm(global_image_coords);
    [ptk_x, ptk_y, ptk_z] = MimImageCoordinateUtilities.CoordinatesMmToPTKCoordinates(x_mm, y_mm, z_mm);
    dicom_coordinates_list = MimImageCoordinateUtilities.ConvertFromPTKCoordinates([ptk_x, ptk_y, ptk_z], MimCoordinateSystem.Dicom, image_data);
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

