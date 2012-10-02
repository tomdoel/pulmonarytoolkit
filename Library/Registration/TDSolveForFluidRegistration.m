function [deformation_field, deformed_image] = TDSolveForFluidRegistration(image_to_transform, reference_image, reporting)
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


    % Initially perform a centroid registration
    [affine_initial_matrix, ~] = TDRegisterCentroid(image_to_transform, reference_image, reporting);

%    % Alternative: perform an initial rigid registration
%     [affine_initial_matrix, transformed_matrix] = TDSolveForRigidRegistration(image_to_transform, reference_image, reporting);
    
    % Find a voxel size to use for the registration image. We divide up thick
    % slices to give an approximately isotropic voxel size
    register_voxel_size = reference_image.VoxelSize;
    register_voxel_size = register_voxel_size./round(register_voxel_size/min(register_voxel_size));
    
    % Resample both images so they have the same image and voxel size
    reference_image2 = reference_image.Copy;
    reference_image2.Resample(register_voxel_size, '*nearest');
    image_to_transform2 = image_to_transform.Copy;
    image_to_transform2.Resample(register_voxel_size, '*nearest');
    
    % Add an extra border to allow for the affine transformation
    image_to_transform2.AddBorder(20);
    TDImageUtilities.MatchSizes(reference_image2, image_to_transform2);
    
    % The fluid registration will be performed after the rigid registration has
    % been performed
    transformed_image = TDRegisterImageAffine(image_to_transform, reference_image2, affine_initial_matrix, '*nearest', reporting);
    
    % Convert to distance transforms
    dt_float = TDImageUtilities.GetNormalisedDT(transformed_image);
    dt_ref = TDImageUtilities.GetNormalisedDT(reference_image2);
    
    % Solve to find the deformation field between these images
    [deformation_field, deformed_image] = Solve(dt_float, dt_ref, reporting);
    
    % Now we need to add the rigid transformation to the deformation field.
    % To do this, compute the change in image coordinates after applying the
    % deformation field and then the rigid affine transformation.
    [df_i, df_j, df_k] = deformation_field.GetCentredGlobalCoordinatesMm;
    [df_i, df_j, df_k] = ndgrid(df_i, df_j, df_k);
    [df_i_t, df_j_t, df_k_t] = TDImageCoordinateUtilities.TransformCoordsFluid(df_i, df_j, df_k, deformation_field);
    [df_i_t, df_j_t, df_k_t] = TDImageCoordinateUtilities.TransformCoordsAffine(df_i_t, df_j_t, df_k_t, affine_initial_matrix);
    
    deformation_field_raw = zeros(deformation_field.ImageSize);
    deformation_field_raw(:,:,:,1) = df_i - df_i_t;
    deformation_field_raw(:,:,:,2) = df_j - df_j_t;
    deformation_field_raw(:,:,:,3) = df_k - df_k_t;
    deformation_field2 = deformation_field.BlankCopy;
    deformation_field2.ChangeRawImage(deformation_field_raw);
    deformation_field = deformation_field2;    
end

function [deformation_field, deformed_image] = Solve(image_1, image_2, reporting)
    deformation_field = image_2.BlankCopy;
    deformed_image = image_2.BlankCopy;
    voxel_size = image_2.VoxelSize;
    if ~isequal(voxel_size, image_1.VoxelSize)
        reporting.Error('TDGetFluidDeformationField:DifferentVoxelSizes', 'Images must have the same voxel size');
    end
    if ~isequal(image_1.ImageSize, image_2.ImageSize)
        reporting.Error('TDGetFluidDeformationField:DifferentVoxelSizes', 'Images must have the same image size');
    end
    
    iterations = 200;
    % X corresponds to image columns and Y image rows
    options = npRegSet('Display', 'iter', 'Regularizer', 'curvature', ...
        'VoxSizeX', voxel_size(2),'VoxSizeY', voxel_size(1), 'VoxSizeZ', voxel_size(3), ...
        'maxiter', iterations, 'RegularizerFactor', 0.01,...
        'BodyForceTol', 0.001, 'BodyForceDiffTol', 0.001, ...
        'BoundaryCond', 'Neumann');
    
    [deformed_image_raw, deformation_field_raw, exit_flag] = npReg(image_2.RawImage, image_1.RawImage, options);
    deformed_image.ChangeRawImage(deformed_image_raw);
    
    if (exit_flag ~= 1)
        reporting.Error('TDGetFluidDeformationField:RegistrationDidNotConverge', 'npReg registration did not converge.');
    end
    
    translation = (image_2.Origin - image_1.Origin).*image_2.VoxelSize;
    deformation_field_raw(:,:,:,1) = deformation_field_raw(:,:,:,1) + translation(1);
    deformation_field_raw(:,:,:,2) = deformation_field_raw(:,:,:,2) + translation(2);
    deformation_field_raw(:,:,:,3) = deformation_field_raw(:,:,:,3) + translation(3);
    
    deformation_field.ChangeRawImage(deformation_field_raw);
end
