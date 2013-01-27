function deformed_image = PTKRegisterImageFluidToMatch(original_image, template_to_match, deformation_field, interpolation_type, reporting)
    % PTKRegisterImageFluidToMatch. Registers an image using a deformation field,
    % to a coordinate system defined by a specified template image
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    deformed_image = PTKRegisterImageFluid(original_image, deformation_field, interpolation_type, reporting);
    deformed_image = PTKRegisterImageZeroDeformationFluid(deformed_image, template_to_match, interpolation_type, reporting);
end

