function [affine_matrix, transformed_matrix] = PTKSolveForRigidRegistration(image_to_transform, reference_image, reporting)
    % PTKSolveForRigidRegistration. Computes the transformation matrix to register one
    %     image segmentation to another based on an solving for a rigid
    %     transformation.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    % Initial centroid registration
    [com_affine_matrix, com_affine_vector] = PTKRegisterCentroid(image_to_transform, reference_image, reporting);

    % Before computing a distance transform, we must resample the images so they are approximately isotropic 
    % Find a voxel size to use for the registration image. We divide up thick
    % slices to give an approximately isotropic voxel size
    register_voxel_size = reference_image.VoxelSize;
    register_voxel_size = register_voxel_size./round(register_voxel_size/min(register_voxel_size));
    reference_image2 = reference_image.Copy;
    reference_image2.ResampleBinary(register_voxel_size);
    image_to_transform2 = image_to_transform.Copy;
    image_to_transform2.ResampleBinary(register_voxel_size);

    
    reference_image2.AddBorder(20);
    image_to_transform2.AddBorder(20);
    
    dt_float = PTKImageUtilities.GetNormalisedDT(image_to_transform2);
    dt_float.RescaleToMaxSize(128);

    dt_ref = PTKImageUtilities.GetNormalisedDT(reference_image2);
    dt_ref.RescaleToMaxSize(128);
    
    [affine_matrix, transformed_matrix] = Solve(dt_float, dt_ref, com_affine_vector, reporting);
end

function [affine_matrix, transformed_matrix] = Solve(image_to_transform, reference_image, starting_affine_vector, reporting)
    [i_o, j_o, k_o] = image_to_transform.GetCentredGlobalCoordinatesMm;
    [i_o, j_o, k_o] = ndgrid(i_o, j_o, k_o);

    [i_r, j_r, k_r] = reference_image.GetCentredGlobalCoordinatesMm;
    [i_r, j_r, k_r] = ndgrid(i_r, j_r, k_r);
    
    x_0 = starting_affine_vector';
    AnonFn = @(x) FnToMinimiseRigid(x, image_to_transform, reference_image, i_o, j_o, k_o, i_r, j_r, k_r, reporting);
    
    [x_vector, fval, exitflag, output] = fminsearch(AnonFn, x_0, optimset('TolX',0.0001, 'TolFun', 0.01, 'PlotFcns', @optimplotfval));
    
    affine_matrix = PTKImageCoordinateUtilities.CreateRigidAffineMatrix(x_vector);

    transformed_matrix = PTKRegisterImageAffineUsingCoordinates(image_to_transform, reference_image, affine_matrix, i_o, j_o, k_o, i_r, j_r, k_r, '*linear', reporting);
end

function closeness = FnToMinimiseRigid(x_vector, image_to_transform, reference_image, i_o, j_o, k_o, i_r, j_r, k_r, reporting)
    affine_matrix = PTKImageCoordinateUtilities.CreateRigidAffineMatrix(x_vector);
    transformed_image = PTKRegisterImageAffineUsingCoordinates(image_to_transform, reference_image, affine_matrix, i_o, j_o, k_o, i_r, j_r, k_r, '*linear', reporting);
    closeness = ComputeCloseness(transformed_image, reference_image);
end

function closeness = ComputeCloseness(image1, image2)
    diff = (image1.RawImage - image2.RawImage).^2;
    closeness = sqrt(sum(diff(:))/numel(image1.RawImage));
end