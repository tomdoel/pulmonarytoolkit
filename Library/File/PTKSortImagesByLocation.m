function [sorted_indices, slice_thickness, global_origin_mm] = PTKSortImagesByLocation(metadata_grouping, reporting)
    % PTKSortImagesByLocation. Sorts a series of Dicom images by their slice
    %     locations and calculates additional image parameters
    %
    %     Syntax:
    %         [sorted_indices, slice_thickness, global_origin_mm] = PTKSortImagesByLocation(metadata_grouping, reporting)
    %
    %     Inputs:
    %         metadata_grouping - A PTKFileGrouping object containing the
    %             metadata from the group of Dicom images to be sorted
    %
    %         reporting - A PTKReporting or implementor of the same interface,
    %             for error and progress reporting. 
    %
    %     Outputs:
    %         sorted_indices - The indices of the metadata structures in
    %             metadata_grouping, ordered by slice location
    %
    %         slice_thickness - A typical slice thickness for this group of
    %             images
    %
    %         global_origin_mm - The coordinates of the first voxel in the image
    %             volume
    %        
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
        image_positions_patient = PTKContainerUtilities.GetMatrixOfFieldValuesFromSet(metadata_grouping.Metadata, 'ImagePositionPatient')';        
    else
        image_positions_patient = [];
    end

    if isfield(representative_metadata, 'SliceLocation')
        slice_locations = PTKContainerUtilities.GetMatrixOfFieldValuesFromSet(metadata_grouping.Metadata, 'SliceLocation')';
    else
        slice_locations = [];
    end
    
    if isfield(representative_metadata, 'InstanceNumber')
        instance_numbers = PTKContainerUtilities.GetMatrixOfFieldValuesFromSet(metadata_grouping.Metadata, 'InstanceNumber')';
    else
        instance_numbers = [];
    end
    
    % We try to calculate the slice locations from the ImagePositionPatient tags
    if ~isempty(image_positions_patient) && isfield(representative_metadata, 'ImageOrientationPatient')
        i_axis = representative_metadata.ImageOrientationPatient(1:3);
        j_axis = representative_metadata.ImageOrientationPatient(4:6);
        
        [~, i_direction] = max(abs(i_axis));
        [~, j_direction] = max(abs(j_axis));
        
        k_direction = setdiff([1, 2, 3], [i_direction, j_direction]);
        if numel(k_direction) ~= 1
            reporting.Error('PTKSortImagesByLocation:UnableToComputeDirection', 'Unable to group the files due to a program error. The computation of the image orientation failed');
        end
            
        [sorted_slice_locations, sorted_indices] = sort(image_positions_patient(:, k_direction), 'ascend');
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
    
    % Remove any zero thicknesses, which may indicate multiple slices at the
    % same position
    if any(slice_thicknesses < 0.01)
        reporting.ShowWarning('PTKSortImagesByLocation:ZeroSliceThickness', 'This image contains more than one image at the same slice position', []);
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
            reporting.ShowWarning('PTKSortImagesByLocation:InconsistentSliceThickness', 'Not all slices have the same thickness', []);
        end
    end
    
    reporting.CompleteProgress;
end
