function match = DMAreImagesInSameGroup(this_metadata, other_metadata, this_metadata_2)
    % Determine whether two Dicom images form a coherent sequence
    %
    % DMAreImagesInSameGroup compares the metadata from two Dicom images. If
    % the images are from the same patient, study and series, and have similar
    % orientations, data types and image types, then they are considered to be
    % part of a coherent sequence.
    %
    %
    % Syntax:
    %     match = DMAreImagesInSameGroup(this_metadata, other_metadata)
    %
    % Parameters:
    %     this_metadata, other_metadata: metadata structures representing
    %         two Dicom images
    %     this_metadata_2: additional image used only for checking that the
    %         image locations form a coherant set
    %
    % Returns:
    %     match - True if the two images form a coherent sequence
    %
    %
    % .. Licence
    %    -------
    %    Part of DicoMat. https://github.com/tomdoel/dicomat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %    
   
    if nargin < 3
        this_metadata_2 = [];
    end
    
    % Check that the main Dicom tags match
    match = CompareMainTags(this_metadata, other_metadata);
    
    % Check that image coordinates lie in a straight line
    if ~isempty(this_metadata_2)
        match = match && CompareMainTags(this_metadata_2, other_metadata);
        match = match && DMAreImageLocationsConsistent(this_metadata, other_metadata, this_metadata_2);
    end
end
    
function match = CompareMainTags(this_metadata, other_metadata)
        
    % Check for exact matches in certain fields
    fields_to_compare = {'PatientName', 'PatientID', 'PatientBirthDate', ...
        'StudyInstanceUID', 'SeriesInstanceUID', 'StudyID', 'StudyDescription', 'SeriesNumber', ...
        'SeriesDescription', 'StudyDate', 'SeriesDate', 'Rows', 'Columns', 'PixelSpacing', ...
        'PatientPosition', 'FrameOfReferenceUID', 'Modality', 'MediaStorageSOPClassUID', ...
        'ImageType', 'SOPClassUID', 'ImplementationClassUID', 'ImagesInAcquisition', ...
        'SamplesPerPixel', 'PhotometricInterpretation', 'BitsAllocated', 'BitsStored', ...
        'HighBit', 'PixelRepresentation'};
    
    is_field_this = isfield(this_metadata, fields_to_compare);
    is_field_other = isfield(other_metadata, fields_to_compare);
    
    % Fields should exist in both metadata or neither
    if any(is_field_other ~= is_field_this)
        match = false;
        return;
    end
    
    fields_to_compare = fields_to_compare(is_field_this);

    for field_name = fields_to_compare
         if ~isequal(this_metadata.(field_name{1}), other_metadata.(field_name{1}))
             match = false;
             return;
         end
    
    end
  
    if ~CompareFieldsInexactMatch('ImageOrientationPatient', this_metadata, other_metadata, 0.5)
        match = false;
        return;
    end
    
    % Verify that the images contain the same tags relating to slice location
    if isfield(this_metadata, 'SliceLocation') ~= isfield(other_metadata, 'SliceLocation')
        match = false;
        return;
    end
    if isfield(this_metadata, 'ImagePositionPatient') ~= isfield(other_metadata, 'ImagePositionPatient')
        match = false;
        return;
    end
    
    if isfield(this_metadata, 'ImagePositionPatient') ~= isfield(other_metadata, 'ImagePositionPatient')
        match = false;
        return;
    end
    
    % If the positions match exactly, then these are should not be in the
    % same group - they may be duplicates, or different time points
    if CompareFieldsInexactMatch('ImagePositionPatient', this_metadata, other_metadata, 0.0001)
        match = false;
        return;
    end
    
    match = true;
end

function matches = CompareFieldsInexactMatch(field_name, this_metadata, other_metadata, tolerance)
    
    % If this field does not exist in either metadata, then return a
    % true match
    if ~isfield(this_metadata, field_name) && ~isfield(other_metadata, field_name)
        matches = true;
        return;
    end
    
    % If this field exists in one but not the other, return a false
    % match
    if isfield(this_metadata, field_name) ~= isfield(other_metadata, field_name)
        matches = false;
        return;
    end
    
    % Get the values of this field
    field_this = this_metadata.(field_name);
    field_other = other_metadata.(field_name);
    
    % If the field values are of a different type, return a false match
    if ~strcmp(class(field_this), class(field_other))
        matches = false;
        return;
    end
    
    % Inexact numeric match
    matches = max(abs(field_this(:) - field_other(:))) < tolerance;
end
