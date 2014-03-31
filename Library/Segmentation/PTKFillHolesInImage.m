function filled_image = PTKFillHolesInImage(original_image)
    % PTKFillHolesInImage. Fills in holes in a binary image.
    %
    %     PTKFillHolesInImage takes in a binary image and fills in any completely
    %     enclosed holes, where holes are regions of value zero surrounded
    %     completely by non-zero values.
    %
    %     The input and output images are of class PTKImage.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if ~isa(original_image, 'PTKImage')
        error('Requires a PTKImage as input');
    end
    original_reduced = original_image.Copy;
    original_reduced.CropToFit;
    filled_image = FillHolesInImage(original_reduced);
    filled_image.ResizeToMatch(original_image);
end



function filled_image = FillHolesInImage(original_image)
    connected_components_structure =  bwconncomp(original_image.RawImage == 0, 6);
    if connected_components_structure.NumObjects == 0
        filled_image =  original_image;
        return;
    end
    labeled_components = labelmatrix(connected_components_structure);
    edge_components = GetAllUnqiueValuesFromImageBoundaries(labeled_components);
    for component_index = edge_components'
        labeled_components(labeled_components == component_index) = 0;
    end
    
    filled_image = original_image.BlankCopy;
    filled_image_raw = original_image.RawImage;
    filled_image_raw(labeled_components > 0) = 1;
    filled_image.ChangeRawImage(filled_image_raw);
end

function edge_components = GetAllUnqiueValuesFromImageBoundaries(labeled_components)
      edge_components_1 = labeled_components([1, end], :, :); 
      edge_components_2 = labeled_components(:, [1, end], :); 
      edge_components_3 = labeled_components(:, :, [1, end]);
      edge_components = unique([edge_components_1(:); edge_components_2(:); edge_components_3(:)]);
end
