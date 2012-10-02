function deformed_image = TDRegisterImageFluid(original_image, deformation_field, interpolation_type, reporting)
    % TDRegisterImageFluid. Registers an image using a deformation field.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    deformed_image = deformation_field.BlankCopy;
    deformed_image.ImageType = TDImageType.Grayscale;
    [i_o, j_o, k_o] = original_image.GetCentredGlobalCoordinatesMm;
    [i_o, j_o, k_o] = ndgrid(i_o, j_o, k_o);
    
    [i_r, j_r, k_r] = deformation_field.GetCentredGlobalCoordinatesMm;
    [i_r, j_r, k_r] = ndgrid(i_r, j_r, k_r);

    % Transform the coordinates using the deformation field
    [i_r, j_r, k_r] = TDImageCoordinateUtilities.TransformCoordsFluid(i_r, j_r, k_r, deformation_field);
    
    % Interpolate the image to the deformed coordinates
    deformed_image_raw = interpn(i_o, j_o, k_o, single(original_image.RawImage), i_r, j_r, k_r, interpolation_type, 0);
   
    deformed_image.ChangeRawImage(deformed_image_raw);
end

