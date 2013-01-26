function deformation_field_combined = TDCombineDeformationFields(deformation_left, deformation_right, left_right_mask)
    % TDCombineDeformationFields. Combines deformation fields for the left and
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
    
    deformation_field_combined = left_right_mask.BlankCopy;
    deformation_field_combined.ChangeRawImage(zeros([deformation_field_combined.ImageSize, 3], 'double'));
    region_mask = left_right_mask.BlankCopy;
    region_mask.ResizeToMatch(deformation_right);
    region_mask.ChangeRawImage(left_right_mask.RawImage == 1);
    deformation_field_combined.ChangeSubImageWithMask(deformation_right, region_mask);
    region_mask.ChangeRawImage(left_right_mask.RawImage == 2);
    region_mask.ResizeToMatch(deformation_left);
    deformation_field_combined.ChangeSubImageWithMask(deformation_left, region_mask);
end

