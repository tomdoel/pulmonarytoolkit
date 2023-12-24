function [sorted_indices, slice_thickness, global_origin_mm, sorted_positions] = DMSortImagesByLocation(metadata_grouping, reporting)
    % Sorts a series of Dicom images by their slice
    % locations and calculates additional image parameters
    %
    % Syntax:
    %     [sorted_indices, slice_thickness, global_origin_mm] = DMSortImagesByLocation(metadata_grouping, reporting)
    %
    % Parameters:
    %     metadata_grouping: A DMFileGrouping object containing the
    %         metadata from the group of Dicom images to be sorted
    %
    %     reporting: A CoreReporting or implementor of the same interface,
    %         for error and progress reporting. 
    %
    % Outputs:
    %     sorted_indices - The indices of the metadata structures in
    %         metadata_grouping, ordered by slice location
    %
    %     slice_thickness - A typical slice thickness for this group of
    %         images
    %
    %     global_origin_mm - The coordinates of the first voxel in the image
    %         volume
    %
    %     sorted_positions - The ImagePositionPatient for
    %         each slice in the sorted 
    %    
    %
    % .. Licence
    %    -------
    %    Part of DicoMat. https://github.com/tomdoel/dicomat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %    
    
    
    reporting.ShowProgress('Ordering images');
    reporting.UpdateProgressValue(0);
    
    % Determine if ImagePositionPatient and SliceLocation tags exist. 
    % It is sufficient to only check the metadata for one image, assuming that
    % the metadata was grouped prior to calling this function. The grouping
    % ensures that within a group, each of these tags exist for either all or no
    % images.
    representative_metadata = metadata_grouping.Metadata{1};
    if isfield(representative_metadata, 'ImagePositionPatient')
        image_positions_patient = CoreContainerUtilities.GetMatrixOfFieldValuesFromSet(metadata_grouping.Metadata, 'ImagePositionPatient')';        
    else
        image_positions_patient = [];
    end

    if isfield(representative_metadata, 'SliceLocation')
        slice_locations = CoreContainerUtilities.GetMatrixOfFieldValuesFromSet(metadata_grouping.Metadata, 'SliceLocation')';
    else
        slice_locations = [];
    end
    
    if isfield(representative_metadata, 'InstanceNumber')
        instance_numbers = CoreContainerUtilities.GetMatrixOfFieldValuesFromSet(metadata_grouping.Metadata, 'InstanceNumber')';
    else
        instance_numbers = [];
    end
    
    % We try to calculate the slice locations from the ImagePositionPatient tags
    if ~isempty(image_positions_patient) && isfield(representative_metadata, 'ImageOrientationPatient')

        % The first slice in the sequence may not be the actual first slice
        % in the image, but this does not matter
        first_slice_position = image_positions_patient(1, :);
        offset_positions = image_positions_patient - repmat(first_slice_position, size(image_positions_patient, 1), 1);
        
        % Work out the relative direction of each slice relative to the
        % 'first' slice
        orientation_1 = representative_metadata.ImageOrientationPatient(1:3);
        orientation_2 = representative_metadata.ImageOrientationPatient(4:6);
        normal_vector = cross(orientation_1, orientation_2)';
        directions = sign(dot(repmat(normal_vector, [size(offset_positions, 1), 1]), offset_positions, 2));
        
        % We compute the displacements of the image positon, which assumes
        % the images form a cuboid stack. Really to compute the slice
        % spacing we should compute the distance of the image position to
        % the plane formed by the image orientation vectors
        image_slice_locations = directions.*sqrt(offset_positions(:, 1).^2 + offset_positions(:, 2).^2 + offset_positions(:, 3).^2);
        
        [sorted_slice_locations, sorted_indices] = sort(image_slice_locations, 'ascend');
        global_origin_mm = min(image_positions_patient, [], 1);
        slice_thicknesses = abs(sorted_slice_locations(2:end) - sorted_slice_locations(1:end-1));
        
        
    % If this tag is not present, we try the SliceLocation tags
    elseif ~isempty(slice_locations)    
        [sorted_slice_locations, sorted_indices] = sort(slice_locations, 'ascend');
        global_origin_mm = [];
        slice_thicknesses = abs(sorted_slice_locations(2:end) - sorted_slice_locations(1:end-1));
    
    % In the absense of the above tags, we sort by the instance number (slice
    % number). Ths is less reliable
    elseif ~isempty(instance_numbers)
        sorted_indices = sort(instance_numbers, 'ascend');
        global_origin_mm = [];
        slice_thicknesses = [];
        
    % Otherwise we set everything to empty
    else
        sorted_indices = [];
        global_origin_mm = [];
        slice_thicknesses = [];
    end
    
    sorted_positions = [];
    if ~isempty(image_positions_patient)
        for slice_number = 1 : size(image_positions_patient, 1)
            sorted_positions(slice_number, :) = image_positions_patient(sorted_indices(slice_number), :);
        end
    end
    
    % Remove any zero thicknesses, which may indicate multiple slices at the
    % same position
    if any(slice_thicknesses < 0.01)
        reporting.ShowWarning('DMSortImagesByLocation:ZeroSliceThickness', 'This image contains more than one image at the same slice position', []);
        slice_thicknesses = slice_thicknesses(slice_thicknesses > 0.01);
    end
    
    % If we have no non-zero slice thicknesses (including the case where we only
    % have a single slice) then try and use the SliceThickness tag if it exists.
    % Otherwise we just set to empty to indicate that we cannot determine this
    if isempty(slice_thicknesses)
        if isfield(metadata_grouping.Metadata{1}, 'SliceThickness')
            slice_thickness = metadata_grouping.Metadata{1}.SliceThickness;
        else
            slice_thickness = [];
        end
    else
        slice_thickness = mode(slice_thicknesses);
        if any((slice_thicknesses - slice_thickness) > 0.01)
            reporting.ShowWarning('DMSortImagesByLocation:InconsistentSliceThickness', 'Not all slices have the same thickness', []);
        end
    end
    
    reporting.CompleteProgress();
end
