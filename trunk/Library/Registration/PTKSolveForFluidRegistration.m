function [deformation_field, deformed_image] = PTKSolveForFluidRegistration(image_to_transform, reference_image, reporting, affine_initial_matrix)
    % PTKSolveForFluidRegistration. Computes the deformation field to register one
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
    isotropic_reference_image = PTKImageUtilities.MakeImageApproximatelyIsotropic(reference_image, 'PTK smoothed binary');
    
    % The fluid registration will be performed after the rigid registration has
    % been performed
    transformed_image = PTKRegisterImageAffine(image_to_transform, isotropic_reference_image, affine_initial_matrix, '*nearest', reporting);
    
    deformation_field = PTKSolveMatchedImagesForFluidRegistration(transformed_image, isotropic_reference_image, reporting);
    
    deformation_field = PTKImageCoordinateUtilities.AdjustDeformationFieldForInitialAffineTransformation(deformation_field, affine_initial_matrix);
    
    deformed_image = PTKRegisterImageFluid(image_to_transform, deformation_field, '*nearest', reporting);
end


function affine_initial_matrix = GetInitialTransformation(image_to_transform, reference_image, reporting)
    % Initially perform a centroid registration
    [affine_initial_matrix, ~] = PTKRegisterCentroid(image_to_transform, reference_image, reporting);

%    % Alternative: perform an initial rigid registration
%     [affine_initial_matrix, transformed_matrix] = PTKSolveForRigidRegistration(image_to_transform, reference_image, reporting);
end