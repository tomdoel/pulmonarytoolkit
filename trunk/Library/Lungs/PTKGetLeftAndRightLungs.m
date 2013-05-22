function results = PTKGetLeftAndRightLungs(unclosed_lungs, filtered_threshold_lung, lung_roi, reporting)
    % PTKGetLeftAndRightLungs. Extracts left and right lungs from a lung
    %     segmentation, with morphological smoothing and hole-flling
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    
    
    min_volume_warning_limit = 2000;
    l_to_r_ratio_limit = 1.5;
    
    results = PTKSeparateAndLabelLungs(unclosed_lungs, filtered_threshold_lung, lung_roi, reporting);
    
    reporting.UpdateProgressAndMessage(25, 'Closing right lung');
    right_lung = results.Copy;
    right_lung.ChangeRawImage(right_lung.RawImage == 1);
    right_lung.CropToFit;
    
    if PTKSoftwareInfo.FastMode
        close_size = 5;
    else
        close_size = 8;
    end
    
    % Perform morphological closing with a spherical structure element
    right_lung.MorphWithBorder(@imclose, close_size);
    
    % Fill any remaining holes inside the 3D image
    right_lung = PTKFillHolesInImage(right_lung);
    
    right_lung.ChangeRawImage(uint8(right_lung.RawImage));

    % Get the right lung volume
    right_lung_volume_mm3 = GetLungVolume(right_lung);
    if right_lung_volume_mm3 < min_volume_warning_limit
        reporting.ShowWarning('PTKGetLeftAndRightLungs:RightLungVolumeSmall', ['The calculated right lung volume ' num2str(right_lung_volume_mm3) 'mm^3 is small. This may indicate pathology or a segmentation error. Please manually verify the lung segmentation.'], [])
    end
    
    reporting.UpdateProgressAndMessage(50, 'Closing left lung');
    left_lung = results.Copy;
    left_lung.ChangeRawImage(left_lung.RawImage == 2);
    left_lung.CropToFit;
    
    % Perform morphological closing with a spherical structure element of radius 8mm
    left_lung.MorphWithBorder(@imclose, close_size);
    % Fill any remaining holes inside the 3D image
    left_lung = PTKFillHolesInImage(left_lung);
    
    left_lung.ChangeRawImage(2*uint8(left_lung.RawImage));
    
    % Get the left lung volume
    left_lung_volume_mm3 = GetLungVolume(left_lung);
    if left_lung_volume_mm3 < min_volume_warning_limit
        reporting.ShowWarning('PTKGetLeftAndRightLungs:LeftLungVolumeSmall', ['The calculated left lung volume ' num2str(right_lung_volume_mm3) 'mm^3 is small. This may indicate pathology or a segmentation error. Please manually verify the lung segmentation.'], [])
    end
    
    if ((left_lung_volume_mm3 / right_lung_volume_mm3) > l_to_r_ratio_limit) || ((right_lung_volume_mm3 / left_lung_volume_mm3) > l_to_r_ratio_limit)
        reporting.ShowWarning('PTKGetLeftAndRightLungs:LeftRightLungVolumeDifference', ['The calculated left ' num2str(left_lung_volume_mm3) 'mm^3 and right ' num2str(right_lung_volume_mm3) 'mm^3 lung volumes are significantly different. This may indicate pathology or a segmentation error. Please manually verify the lung segmentation.'], [])
    end
    
    reporting.UpdateProgressAndMessage(75, 'Combining');
    
    results.Clear;
    results.ChangeSubImage(left_lung);
    results2 = results.Copy;
    results2.Clear;
    results2.ChangeSubImage(right_lung);
    results.ChangeRawImage(min(2, results.RawImage + results2.RawImage));
    results.ImageType = PTKImageType.Colormap;
end

function lung_volume_mm3 = GetLungVolume(lung_mask)
    voxel_size = lung_mask.VoxelSize;
    voxel_volume_mm3 = voxel_size(1) * voxel_size(2) * voxel_size(3);
    lung_volume_mm3 = sum(lung_mask.RawImage(:))*voxel_volume_mm3;
end

