function match = PTKAreImagesInSameGroup(this_metadata, other_metadata, this_metadata_2)
    % PTKAreImagesInSameGroup. Determines whether two Dicom images form a coherent sequence
    %
    % PTKAreImagesInSameGroup compares the metadata from two Dicom images. If
    % the images are from the same patient, study and series, and have similar
    % orientations, data types and image types, then they are considered to be
    % part of a coherent sequence.
    %
    %
    %     Syntax:
    %         match = PTKAreImagesInSameGroup(this_metadata, other_metadata)
    %
    %     Inputs:
    %         this_metadata, other_metadata - metadata structures representing
    %             two Dicom images
    %         this_metadata_2 - additional image used only for checking that the
    %             image locations form a coherant set
    %
    %     Outputs:
    %         match - True if the two images form a coherent sequence
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
   
    if nargin < 3
        this_metadata_2 = [];
    end
    
    % Check that the main Dicom tags match
    match = CompareMainTags(this_metadata, other_metadata);
    
    % Check that image coordinates lie in a straight line
    if ~isempty(this_metadata_2)
        match = match && CompareMainTags(this_metadata_2, other_metadata);
        match = match && PTKDicomUtilities.AreImageLocationsConsistent(this_metadata, other_metadata, this_metadata_2);
    end
end
    
function match = CompareMainTags(this_metadata, other_metadata)
        
    % Verify that this is the same patient
    if ~CompareFields('PatientName', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('PatientID', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('PatientBirthDate', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    
    
    % Verify that this is the same study and series
    if ~CompareFields('StudyInstanceUID', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('SeriesInstanceUID', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('StudyID', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('StudyDescription', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('SeriesNumber', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('SeriesDescription', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('StudyDate', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('SeriesDate', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    
    
    % Verify the image dimensions are the same
    if ~CompareFields('Rows', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('Columns', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('Width', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('Height', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('PixelSpacing', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    
    % Verify the patient location and orientation are the same
    if ~CompareFields('PatientPosition', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('ImageOrientationPatient', this_metadata, other_metadata, false)
        match = false;
        return;
    end
    
    if ~CompareFields('FrameOfReferenceUID', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    
    
    
    
    % Verify the imaging parameters are the same
    if ~CompareFields('Modality', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('BitDepth', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('ColorType', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('MediaStorageSOPClassUID', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('ImageType', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('SOPClassUID', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('ImplementationClassUID', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('ImagesInAcquisition', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('SamplesPerPixel', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('PhotometricInterpretation', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('BitsAllocated', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('BitsStored', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('HighBit', this_metadata, other_metadata, true)
        match = false;
        return;
    end
    
    if ~CompareFields('PixelRepresentation', this_metadata, other_metadata, true)
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
    
    
    
    match = true;
end

function matches = CompareFields(field_name, this_metadata, other_metadata, exact_match)
    
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
    
    if exact_match || ~isnumeric(field_this)
        matches = isequal(field_this, field_other);
    else
        % Inexact numeric match
        matches = max(field_this(:) - field_other(:)) < 0.5;
    end
end

