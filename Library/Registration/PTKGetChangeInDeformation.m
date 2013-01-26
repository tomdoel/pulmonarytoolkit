function deformation_field = TDGetChangeInDeformation(deformation_field, rigid_affine_matrix)
    % TDGetChangeInDeformation. Computes the deformation field relative to an
    %     original affine translation
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    deformation_field_raw = deformation_field.RawImage;
    deformation_field = deformation_field.BlankCopy;
    deformation_field_raw(:,:,:,1) = deformation_field_raw(:,:,:,1) + rigid_affine_matrix(2, 4);
    deformation_field_raw(:,:,:,2) = deformation_field_raw(:,:,:,2) + rigid_affine_matrix(1, 4);
    deformation_field_raw(:,:,:,3) = deformation_field_raw(:,:,:,3) + rigid_affine_matrix(3, 4);
    deformation_field.ChangeRawImage(deformation_field_raw);

end
