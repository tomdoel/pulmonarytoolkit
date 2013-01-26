function transformed_image = TDRegisterImageAffine(image_to_transform, template_to_match, affine_matrix, interpolation_type, reporting)
    % TDRegisterImageAffine. Computes the transformation matrix to register one
    %     image segmentation to another based on an affine transformation.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    [i_r, j_r, k_r] = template_to_match.GetCentredGlobalCoordinatesMm;
    [i_r, j_r, k_r] = ndgrid(i_r, j_r, k_r);
    [i_o, j_o, k_o] = image_to_transform.GetCentredGlobalCoordinatesMm;
    [i_o, j_o, k_o] = ndgrid(i_o, j_o, k_o);
    transformed_image = TDRegisterImageAffineUsingCoordinates(image_to_transform, template_to_match, affine_matrix, i_o, j_o, k_o, i_r, j_r, k_r, interpolation_type, reporting);
end
