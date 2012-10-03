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
    isotropic_reference_image = MakeImageApproximatelyIsotropic(reference_image);
    
    % The fluid registration will be performed after the rigid registration has
    % been performed
    transformed_image = TDRegisterImageAffine(image_to_transform, isotropic_reference_image, affine_initial_matrix, '*nearest', reporting);
    
    [deformation_field, ~] = SolveMatchedImagesForFluidRegistration(transformed_image, isotropic_reference_image, reporting);
    
    deformation_field = AdjustDeformationFieldForInitialAffineTransformation(deformation_field, affine_initial_matrix);
    
    deformed_image = TDRegisterImageFluid(image_to_transform, deformation_field, '*nearest', reporting);
end

function reference_image2 = MakeImageApproximatelyIsotropic(reference_image)
    
    % Find a voxel size to use for the registration image. We divide up thick
    % slices to give an approximately isotropic voxel size
    register_voxel_size = reference_image.VoxelSize;
    register_voxel_size = register_voxel_size./round(register_voxel_size/min(register_voxel_size));
    
    % Resample both images so they have the same image and voxel size
    reference_image2 = reference_image.Copy;
    reference_image2.ResampleBinary(register_voxel_size);    
end
    
function [deformation_field, deformed_image] = SolveMatchedImagesForFluidRegistration(image_to_transform, reference_image, reporting)
    TDImageUtilities.MatchSizes(reference_image, image_to_transform);
    
    if ~isequal(image_to_transform.VoxelSize, reference_image.VoxelSize)
        reporting.Error('SolveMatchedImagesForFluidRegistration:UnequalVoxelSize', 'SolveMatchedImagesForFluidRegistration requires images to have the same voxel size');
    end
    
    % Convert to distance transforms
    dt_float = TDImageUtilities.GetNormalisedDT(image_to_transform);
    dt_ref = TDImageUtilities.GetNormalisedDT(reference_image);
    
    % Solve to find the deformation field between these images
    [deformation_field, deformed_image] = Solve(dt_float, dt_ref, reporting);
end

function deformation_field = AdjustDeformationFieldForInitialAffineTransformation(deformation_field, affine_initial_matrix)
    
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

function affine_initial_matrix = GetInitialTransformation(image_to_transform, reference_image, reporting)
    % Initially perform a centroid registration
    [affine_initial_matrix, ~] = TDRegisterCentroid(image_to_transform, reference_image, reporting);

%    % Alternative: perform an initial rigid registration
%     [affine_initial_matrix, transformed_matrix] = TDSolveForRigidRegistration(image_to_transform, reference_image, reporting);
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
    options = npRegSet(...
        'Display', 'iter', ...
        'Regularizer', 'curvature', ... % elastic | {fluid} | diffusion | curvature
        'BoundaryCond', 'Neumann', ...
        'VoxSizeX', voxel_size(2),'VoxSizeY', voxel_size(1), 'VoxSizeZ', voxel_size(3), ...
        'maxiter', iterations, ...
        'RegularizerFactor', 1,...
        'BodyForceTol', 0.001, ... % Termination tolerance on the body force [1e-2]
        'BodyForceDiffTol', 0.001, ... % Termination tolerance on the difference between successive body force estimates [1e-2]..
        'SimMeasPercentDiffTol', 0.001 ... % Termination tolerance on the percentage difference between successive similarity measure estimates [ positive scalar {1e-2} ]
        );

%         'SimilarityMeasure', 'SSD', ... % [ {SSD} | NCC | CR | MI | NMI ]
%UDiffTol - Fixed point iteration termination tolerance on the maximum sum 
%       of squared differences between successive displacement field 
%       estimates [ positive scalar {1e-2} ]
%UDiffTol - Fixed point iteration termination tolerance on the maximum sum 
%       of squared differences between successive velocity field estimates
%           [ positive scalar {1e-2} ]
%SimMeasTol - Fixed point iteration termination tolerance on the similarity
%       measure [ positive scalar {1e-2} ]
%SimMeasDiffTol - Fixed point iteration termination tolerance on the
%       difference between successive similarity measure estimates
%           [ positive scalar {1e-2} ]
%SimMeasPercentDiffTol - Fixed point iteration termination tolerance on
%       the percentage difference between successive similarity measure
%       estimates [ positive scalar {1e-2} ]
%FixedPointMaxFlowDistance - Maximum distance (in voxels) that the
%       deformation field is allowed to flow during each fixed point
%       iteration [ positive scalar {5.0} ]
%RegridTol - Tolerance on the Jacobian of the deformation field, below which
%       regridding will take place [ positive scalar {0.0025} ]
%Mu - Lame constant for use with elastic or fluid regularizers
%           [ positive scalar {1.0} ]
%Lambda - Lame constant for use with elastic or fluid regularizers
%           [ nonnegative scalar {0.0} ]
    [deformed_image_raw, deformation_field_raw, exit_flag] = npReg(image_2.RawImage, image_1.RawImage, options);
    deformed_image.ChangeRawImage(deformed_image_raw);
    
    if (exit_flag ~= 1)
        reporting.Warning('TDGetFluidDeformationField:RegistrationDidNotConverge', 'npReg registration did not converge.', []);
    end
    
    translation = (image_2.Origin - image_1.Origin).*image_2.VoxelSize;
    deformation_field_raw(:,:,:,1) = deformation_field_raw(:,:,:,1) + translation(1);
    deformation_field_raw(:,:,:,2) = deformation_field_raw(:,:,:,2) + translation(2);
    deformation_field_raw(:,:,:,3) = deformation_field_raw(:,:,:,3) + translation(3);
    
    deformation_field.ChangeRawImage(deformation_field_raw);
end
