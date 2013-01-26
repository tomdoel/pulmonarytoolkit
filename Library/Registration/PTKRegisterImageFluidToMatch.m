function deformed_image = TDRegisterImageFluidToMatch(original_image, template_to_match, deformation_field, interpolation_type, reporting)
    % TDRegisterImageFluidToMatch. Registers an image using a deformation field,
    % to a coordinate system defined by a specified template image
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    deformed_image = TDRegisterImageFluid(original_image, deformation_field, interpolation_type, reporting);
    deformed_image = TDRegisterImageZeroDeformationFluid(deformed_image, template_to_match, interpolation_type, reporting);
end

