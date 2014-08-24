function results = PTKMapLobesToImage(lobes, gas_image_template, fluid_deformation_field_right, lung_ct_right, fluid_deformation_field_left, lung_ct_left, reporting)
    % PTKMapLobesToImage. Computes a lobar map for an image given a deformation field
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    lobes_ct_right = lobes;
    lobes_ct_left = lobes_ct_right.Copy;
    results = gas_image_template.Copy;
    
    
    % Right lung
    lobes_ct_right.ResizeToMatch(lung_ct_right);
    lobes_ct_right.ChangeRawImage(uint8(uint8(lobes_ct_right.RawImage).*uint8(lung_ct_right.RawImage > 0)));
    
    deformed_ct_lobes_right = PTKRegisterImageFluid(lobes_ct_right, fluid_deformation_field_right, '*nearest', reporting);
    deformed_ct_lobes_right = PTKRegisterImageZeroDeformationFluid(deformed_ct_lobes_right, gas_image_template, '*nearest', reporting);
    
    
    % Left lung
    lobes_ct_left.ResizeToMatch(lung_ct_left);
    lobes_ct_left.ChangeRawImage(uint8(uint8(lobes_ct_left.RawImage).*uint8(lung_ct_left.RawImage > 0)));
    
    deformed_ct_lobes_left = PTKRegisterImageFluid(lobes_ct_left, fluid_deformation_field_left, '*nearest', reporting);
    deformed_ct_lobes_left = PTKRegisterImageZeroDeformationFluid(deformed_ct_lobes_left, gas_image_template, '*nearest', reporting);
    
    
    % Combine
    results.ChangeRawImage(zeros(results.ImageSize, 'uint8'));
    
    right_lung_mask = deformed_ct_lobes_right.Copy;
    right_lung_mask.ChangeRawImage((right_lung_mask.RawImage == 1) | (right_lung_mask.RawImage == 2) | (right_lung_mask.RawImage == 4));
    results.ChangeSubImageWithMask(deformed_ct_lobes_right, right_lung_mask);
    
    left_lung_mask = deformed_ct_lobes_left.Copy;
    left_lung_mask.ChangeRawImage((left_lung_mask.RawImage == 5) | (left_lung_mask.RawImage == 6));
    results.ChangeSubImageWithMask(deformed_ct_lobes_left, left_lung_mask);
    
    results.ImageType = PTKImageType.Colormap;
    
end