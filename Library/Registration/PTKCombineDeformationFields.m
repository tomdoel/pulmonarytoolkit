function deformation_field_combined = PTKCombineDeformationFields(deformation_left, deformation_right, left_right_mask)
    % PTKCombineDeformationFields. Combines deformation fields for the left and
    % right lungs
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    
    % Resample the mask if necessary. This may be necessary if the deformation
    % was computed with a higher resolution image than the actual data
    if ~isequal(left_right_mask.VoxelSize, deformation_left.VoxelSize)
        left_right_mask = left_right_mask.Copy;
        left_right_mask.Resample(deformation_left.VoxelSize, '*nearest');
    end
    
    % Create a combined deformation field
    deformation_field_combined = left_right_mask.BlankCopy;
    deformation_field_combined.ChangeRawImage(zeros([deformation_field_combined.ImageSize, 3], 'double'));

    % Create a mask of the deformation regions which have been set
    has_been_set_mask = left_right_mask.BlankCopy;
    has_been_set_mask.ChangeRawImage(false([left_right_mask.ImageSize]));
    
    % Set the deformations for the left lung
    region_mask = left_right_mask.BlankCopy;
    region_mask.ChangeRawImage(left_right_mask.RawImage == 1);
    region_mask.ResizeToMatch(deformation_right);
    deformation_field_combined.ChangeSubImageWithMask(deformation_right, region_mask);
    has_been_set_mask.ChangeSubImageWithMask(region_mask, region_mask);
    
    % Set the deformations for the right lung
    region_mask = left_right_mask.BlankCopy;
    region_mask.ChangeRawImage(left_right_mask.RawImage == 2);
    region_mask.ResizeToMatch(deformation_left);
    deformation_field_combined.ChangeSubImageWithMask(deformation_left, region_mask);
    has_been_set_mask.ChangeSubImageWithMask(region_mask, region_mask);
    
    % Fill in the unset regions using the deformation values of the nearest
    % points
    [~, nn_index] = bwdist(has_been_set_mask.RawImage);
    nn_deformation_field = left_right_mask.BlankCopy;
    nn_deformation_field_raw = zeros([deformation_field_combined.ImageSize], 'double');
    
    deformation_field_combined_component = deformation_field_combined.RawImage(:, :, :, 1);
    nn_deformation_field_raw(:, :, :, 1) = deformation_field_combined_component(nn_index);
    deformation_field_combined_component = deformation_field_combined.RawImage(:, :, :, 2);
    nn_deformation_field_raw(:, :, :, 2) = deformation_field_combined_component(nn_index);
    deformation_field_combined_component = deformation_field_combined.RawImage(:, :, :, 3);
    nn_deformation_field_raw(:, :, :, 3) = deformation_field_combined_component(nn_index);
    
    nn_deformation_field.ChangeRawImage(nn_deformation_field_raw);
    has_been_set_mask.ChangeRawImage(~has_been_set_mask.RawImage);
    deformation_field_combined.ChangeSubImageWithMask(nn_deformation_field, has_been_set_mask);
    
end

