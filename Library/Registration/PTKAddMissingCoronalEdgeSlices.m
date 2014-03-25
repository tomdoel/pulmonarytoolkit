function new_mask = PTKAddMissingCoronalEdgeSlices(mask_image, resample_voxel_size)
    % PTKAddMissingCoronalEdgeSlices.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    bounds = mask_image.GetBounds;
    mask_resampled = mask_image.Copy;
    new_mask = mask_image.Copy;
    
    if (bounds(1) <= 2) || (bounds(2) >=  (mask_resampled.ImageSize(1)-1))
        mask_resampled.AddBorder(1);
        new_mask.AddBorder(1);
        bounds = new_mask.GetBounds;
    end
    mask_resampled.Resample(resample_voxel_size, '*nearest');
    mask_resampled = PTKGaussianFilter(mask_resampled, 20);
    mask_resampled.ChangeRawImage(mask_resampled.RawImage > 0.5);
    mask_resampled.Resample(mask_image.VoxelSize, '*nearest');
    mask_resampled.ResizeToMatch(new_mask);

    slice_min_i = mask_resampled.GetSlice(bounds(1), PTKImageOrientation.Coronal);
    new_mask.ReplaceImageSlice(slice_min_i, bounds(1)-1, PTKImageOrientation.Coronal);
    slice_max_i = mask_resampled.GetSlice(bounds(2), PTKImageOrientation.Coronal);
    new_mask.ReplaceImageSlice(slice_max_i, bounds(2)+1, PTKImageOrientation.Coronal);
end

