function hessian_components = TDGetHessianComponents(image_data)
    % TDGetHessianComponents. Computes the Hessian matrices for an image
    %
    %     TDGetHessianComponents computes the components of the Hessian matrix
    %     for each voxel in the 3D image specified in the TDImage class
    %     image_data. Since the Hessian is symmetric, there are 6 independent
    %     components of the matrix for each voxel; these are returned in the 6xn
    %     matrix hessian_components, where there are n voxels and each row
    %     contains the components for that voxel:
    %
    %         [ H(1,1), H(1,2), H(1,3), H(2,3), H(2,4), H(3,3) ]
    %
    %     The input image is of class TDImage.
    %     The output image is of clas TDWrapper.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    

    hessian_components = TDWrapper;
    hessian_components.RawImage = zeros([6, numel(image_data.RawImage)], 'single');
    hessian_components.RawImage(1, :) = Der2CentralDifference(image_data, 1); %ii
    hessian_components.RawImage(2, :) = Der1(image_data, 3); %ij
    hessian_components.RawImage(3, :) = Der1(image_data, 2); %ik
    hessian_components.RawImage(4, :) = Der2CentralDifference(image_data, 2); %jj
    hessian_components.RawImage(5, :) = Der1(image_data, 1); %jk
    hessian_components.RawImage(6, :) = Der2CentralDifference(image_data, 3); %kk
end

function cd = Der2CentralDifference(image_data, dimension)
    ker = [];
    ker{1} = cast([1; -2; 1], 'single');
    ker{2} = cast([1, -2, 1], 'single');
    ker{3} = cast(permute([1, -2, 1], [3 1 2]), 'single');
    
    cd = single(convn(image_data.RawImage, ker{dimension}, 'same'));
    cd = reshape(cd, [1 numel(cd)]);
end

function cd = Der1(image_data, orthog_dir)
    ker = [1, -1, 0; -1, 1, 0; 0, 0, 0];
    if orthog_dir == 1
        ker = permute(ker, [3 1 2]);
    elseif orthog_dir == 2
        ker = permute(ker, [1 3 2]);
    end
    cd = single(convn(image_data.RawImage, ker, 'same'));
    cd = reshape(cd, [1 numel(cd)]);
end
