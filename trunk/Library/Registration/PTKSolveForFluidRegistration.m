function [deformation_field, deformed_image] = TDSolveForFluidRegistration(image_to_transform, reference_image, reporting, affine_initial_matrix)
    % TDSolveForFluidRegistration. Computes the deformation field to register one
    %     image segmentation to another based on solving a fluid registration.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    if nargin < 4
        affine_initial_matrix = [];
    end
    
    if isempty(affine_initial_matrix)
        affine_initial_matrix = GetInitialTransformation(image_to_transform, reference_image, reporting);
    end

    % For the fluid registration, the images must be the same size and have the
    % same voxel size
    isotropic_reference_image = TDImageUtilities.MakeImageApproximatelyIsotropic(reference_image, 'PTK smoothed binary');
    
    % The fluid registration will be performed after the rigid registration has
    % been performed
    transformed_image = TDRegisterImageAffine(image_to_transform, isotropic_reference_image, affine_initial_matrix, '*nearest', reporting);
    
    deformation_field = TDSolveMatchedImagesForFluidRegistration(transformed_image, isotropic_reference_image, reporting);
    
    deformation_field = TDImageCoordinateUtilities.AdjustDeformationFieldForInitialAffineTransformation(deformation_field, affine_initial_matrix);
    
    deformed_image = TDRegisterImageFluid(image_to_transform, deformation_field, '*nearest', reporting);
end


function affine_initial_matrix = GetInitialTransformation(image_to_transform, reference_image, reporting)
    % Initially perform a centroid registration
    [affine_initial_matrix, ~] = TDRegisterCentroid(image_to_transform, reference_image, reporting);

%    % Alternative: perform an initial rigid registration
%     [affine_initial_matrix, transformed_matrix] = TDSolveForRigidRegistration(image_to_transform, reference_image, reporting);
end