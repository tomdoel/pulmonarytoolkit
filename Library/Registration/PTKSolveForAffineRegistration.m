function [affine_matrix, transformed_matrix] = PTKSolveForAffineRegistration(image_to_transform, reference_image, reporting)
    % PTKSolveForAffineRegistration. Computes the transformation matrix to register one
    %     image segmentation to another based on an solving for an affine
    %     transformation.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    disp('Fetching coordinates');
    [i_o, j_o, k_o] = image_to_transform.GetCentredGlobalCoordinatesMm;
    [i_o, j_o, k_o] = ndgrid(i_o, j_o, k_o);

    disp('Fetching reference coordinates');
    [i_r, j_r, k_r] = reference_image.GetCentredGlobalCoordinatesMm;
    [i_r, j_r, k_r] = ndgrid(i_r, j_r, k_r);

    % Initial guess for affine matrix
    x_0 = [1 0 0 0; 0 1 0 0; 0 0 1 0];
    
    % Create an anonymous function for the solution method
    AnonFn = @(x) FnToMinimise(x, image_to_transform, reference_image, i_o, j_o, k_o, i_r, j_r, k_r, reporting);
    
    disp('Solving');
    [x_vector, ~, ~] = fminsearch(AnonFn, x_0, optimset('TolX',1e-3, 'TolFun', 10, 'PlotFcns', @optimplotfval));
    
    disp(['Computing solution for ' num2str(x_vector(:)')]);
    
    affine_matrix = PTKImageCoordinateUtilities.GetAffineMatrix(x_vector);

    transformed_matrix = PTKImageCoordinateUtilities.TransformAffine(image_to_transform, affine_matrix, i_o, j_o, k_o, i_r, j_r, k_r);
end

function closeness = FnToMinimise(x_vector, image_to_transform, reference_image, i_o, j_o, k_o, i_r, j_r, k_r, reporting)
    affine_matrix = PTKImageCoordinateUtilities.CreateAffineMatrix(x_vector);
    transformed_image = PTKRegisterImageAffineUsingCoordinates(image_to_transform, reference_image, affine_matrix, i_o, j_o, k_o, i_r, j_r, k_r, '*linear', reporting);
    closeness = ComputeCloseness(transformed_image, reference_image);
end

function closeness = ComputeCloseness(image1, image2)
    diff = (image1 - image2).^2;
    closeness = sqrt(sum(diff(:))/numel(image1));
end