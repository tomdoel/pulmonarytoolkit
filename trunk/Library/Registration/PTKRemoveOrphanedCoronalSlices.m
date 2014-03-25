function PTKRemoveOrphanedCoronalSlices(mask_1, mask_2)
    % PTKRemoveOrphanedCoronalSlices.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    for coronal_index = 1 : mask_1.ImageSize(1);
        slice_1 = mask_1.GetSlice(coronal_index, PTKImageOrientation.Coronal);
        slice_2 = mask_2.GetSlice(coronal_index, PTKImageOrientation.Coronal);
        if any(slice_1(:)) && ~any(slice_2(:))
            slice_1(:) = 0;
            mask_1.ReplaceImageSlice(slice_1, coronal_index, PTKImageOrientation.Coronal);
        end
        if any(slice_2(:)) && ~any(slice_1(:))
            slice_2(:) = 0;
            mask_2.ReplaceImageSlice(slice_2, coronal_index, PTKImageOrientation.Coronal);
        end
    end
end

