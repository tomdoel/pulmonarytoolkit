function transformed_matrix = PTKRegisterImageAffineUsingCoordinates(image_to_transform, template_to_match, affine_matrix, i_o, j_o, k_o, i_r, j_r, k_r, interpolation_type, reporting)
    % PTKRegisterImageAffineUsingCoordinates. Computes the transformation matrix to register one
    %     image segmentation to another based on an solving for an affine
    %     transformation.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    % We use augmented matrices for the affine transformation
    [it, jt, kt] = PTKImageCoordinateUtilities.TransformCoordsAffine(i_r, j_r, k_r, affine_matrix);

    % If we are using nearest point interpolation we should keep the same data
    % type as the source image; otherwise we shoud change to a floating point
    % type to allow interpolation of integer grayscale values
    if strcmp(interpolation_type, 'nearest') || strcmp(interpolation_type, '*nearest')
        transformed_matrix_raw = interpn(i_o, j_o, k_o, image_to_transform.RawImage, it, jt, kt, interpolation_type, 0);
    else
        transformed_matrix_raw = interpn(i_o, j_o, k_o, single(image_to_transform.RawImage), it, jt, kt, interpolation_type, 0);
    end
    transformed_matrix = template_to_match.BlankCopy;
    transformed_matrix.ChangeRawImage(transformed_matrix_raw);
end

