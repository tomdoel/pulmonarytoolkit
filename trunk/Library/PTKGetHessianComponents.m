function hessian_components = PTKGetHessianComponents(image_data, mask)
    % PTKGetHessianComponents. Computes the Hessian matrices for an image
    %
    %     PTKGetHessianComponents computes the components of the Hessian matrix
    %     for each voxel in the 3D image specified in the PTKImage class
    %     image_data. Since the Hessian is symmetric, there are 6 independent
    %     components of the matrix for each voxel; these are returned in the 6xn
    %     matrix hessian_components, where there are n voxels and each row
    %     contains the components for that voxel:
    %
    %         [ H(1,1), H(1,2), H(1,3), H(2,3), H(2,4), H(3,3) ]
    %
    %     The input image is of class PTKImage.
    %     The output image is of clas PTKWrapper.
    %
    %     mask is an optional logical image mask specifying the points for which 
    %     the Hessian should be computed. It should be of type PTKImage or
    %     PTKWrapper.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    

    if nargin < 2
        mask = [];
    end
    
    hessian_components = PTKWrapper;
    if isempty(mask)
        num_points = numel(image_data.RawImage);
    else
        num_points = sum(mask.RawImage(:));
    end
    hessian_components.RawImage = zeros([6, num_points], 'single');
    hessian_components.RawImage(1, :) = Der2CentralDifference(image_data, 1, mask); %ii
    hessian_components.RawImage(2, :) = Der1(image_data, 3, mask); %ij
    hessian_components.RawImage(3, :) = Der1(image_data, 2, mask); %ik
    hessian_components.RawImage(4, :) = Der2CentralDifference(image_data, 2, mask); %jj
    hessian_components.RawImage(5, :) = Der1(image_data, 1, mask); %jk
    hessian_components.RawImage(6, :) = Der2CentralDifference(image_data, 3, mask); %kk
end

function cd = Der2CentralDifference(image_data, dimension, mask)
    scaling = image_data.VoxelSize(dimension)*image_data.VoxelSize(dimension);
    ker = [];
    ker{1} = cast([1; -2; 1], 'single');
    ker{2} = cast([1, -2, 1], 'single');
    ker{3} = cast(permute([1, -2, 1], [3 1 2]), 'single');
    
    cd = single(convn(image_data.RawImage, ker{dimension}/(scaling), 'same'));
    if isempty(mask)
        cd = reshape(cd, [1 numel(cd)]);
    else
        cd = cd(mask.RawImage(:));
        cd = cd';
    end
    
end

function cd = Der1(image_data, orthog_dir, mask)
    ker = [1, -1, 0; -1, 1, 0; 0, 0, 0];
    if orthog_dir == 1
        ker = permute(ker, [3 1 2])/(image_data.VoxelSize(2)*image_data.VoxelSize(3));
    elseif orthog_dir == 2
        ker = permute(ker, [1 3 2])/(image_data.VoxelSize(1)*image_data.VoxelSize(3));
    else
        ker = ker/(image_data.VoxelSize(1)*image_data.VoxelSize(2));
    end
    cd = single(convn(image_data.RawImage, ker, 'same'));
    if isempty(mask)
        cd = reshape(cd, [1 numel(cd)]);
    else
        cd = cd(mask.RawImage(:));
        cd = cd';
    end
end
