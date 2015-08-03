function match = DMAreImageLocationsConsistent(first_metadata, second_metadata, third_metadata)
    % DMAreImageLocationsConsistent Determines if several Dicom images are
    % parallel and lie approximately on a straight line, i.e. they form a
    % volume
    % 
    % Returns true if three images lie approximately on a straight line (determined
    % by the coordinates in the ImagePositionPatient Dicom tags)
    %
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
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

