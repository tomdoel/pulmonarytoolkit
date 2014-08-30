function deformation_field = PTKSolveMatchedImagesForFluidRegistration(image_to_transform, reference_image, reporting)
    % PTKSolveMatchedImagesForFluidRegistration. 
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    PTKImageUtilities.MatchSizes(reference_image, image_to_transform);
    
    if ~isequal(image_to_transform.VoxelSize, reference_image.VoxelSize)
        reporting.Error('SolveMatchedImagesForFluidRegistration:UnequalVoxelSize', 'SolveMatchedImagesForFluidRegistration requires images to have the same voxel size');
    end
    
    % Convert to distance transforms
    dt_float = PTKRunForEachComponentAndCombine(@PTKImageUtilities.GetNormalisedDT, image_to_transform, image_to_transform, reporting);
    dt_ref = PTKRunForEachComponentAndCombine(@PTKImageUtilities.GetNormalisedDT, reference_image, reference_image, reporting);
    
    % Solve to find the deformation field between these images
    [deformation_field, ~] = Solve(dt_float, dt_ref, reporting);
end

function [deformation_field, deformed_image] = Solve(image_1, image_2, reporting)
    deformation_field = image_2.BlankCopy;
    deformed_image = image_2.BlankCopy;
    voxel_size = image_2.VoxelSize;
    if ~isequal(voxel_size, image_1.VoxelSize)
        reporting.Error('PTKGetFluidDeformationField:DifferentVoxelSizes', 'Images must have the same voxel size');
    end
    if ~isequal(image_1.ImageSize, image_2.ImageSize)
        reporting.Error('PTKGetFluidDeformationField:DifferentVoxelSizes', 'Images must have the same image size');
    end
    
    if PTKSoftwareInfo.ShowRegistrationConvergence
        display_value = 'iter';
    else
        display_value = 'off';
    end
    iterations = 200;
    % X corresponds to image columns and Y image rows
    options = npRegSet(...
        'Display', display_value, ...
        'Regularizer', 'curvature', ... % elastic | {fluid} | diffusion | curvature
        'BoundaryCond', 'Neumann', ...
        'VoxSizeX', voxel_size(2),'VoxSizeY', voxel_size(1), 'VoxSizeZ', voxel_size(3), ...
        'maxiter', iterations, ...
        'RegularizerFactor', 1,...
        'BodyForceTol', PTKSoftwareInfo.RegistrationBodyForceTol, ... % Termination tolerance on the body force [1e-2]
        'BodyForceDiffTol', PTKSoftwareInfo.RegistrationBodyForceDiffTol, ... % Termination tolerance on the difference between successive body force estimates [1e-2]..
        'SimMeasPercentDiffTol', 0.001, ... % Termination tolerance on the percentage difference between successive similarity measure estimates [ positive scalar {1e-2} ]
        'FixedPointMaxFlowDistance', 5 ...
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
        reporting.ShowWarning('PTKGetFluidDeformationField:RegistrationDidNotConverge', 'npReg registration did not converge.', []);
    end
    
    translation = (image_2.Origin - image_1.Origin).*image_2.VoxelSize;
    deformation_field_raw(:,:,:,1) = deformation_field_raw(:,:,:,1) + translation(1);
    deformation_field_raw(:,:,:,2) = deformation_field_raw(:,:,:,2) + translation(2);
    deformation_field_raw(:,:,:,3) = deformation_field_raw(:,:,:,3) + translation(3);
    
    deformation_field.ChangeRawImage(deformation_field_raw);
end
