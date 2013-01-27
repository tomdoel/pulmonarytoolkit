function filtered_image = PTKGaussianFilter(original_image, filter_size_mm)
    % PTKGaussianFilter. Performs 3D Gaussian filtering on a 3D image.
    %
    %     PTKGaussianFilter takes in an image in a PTKImage class and performs 3D
    %     Gaussian filtering. The sigma size is specified in mm; this function
    %     takes into account the voxel size.
    %
    %     The input and output images are of class PTKImage.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    

    if ~isa(original_image, 'PTKImage')
        error('PTKGaussianFilter requires a PTKImage as input');
    end
    
    voxel_size_mm = original_image.VoxelSize;
    sigma_mm = filter_size_mm;
    
    epsilon = 1e-3;
    sigma_voxels = sigma_mm./voxel_size_mm;
    hsize = 2*max(ceil((sigma_voxels).*sqrt(-2*log(sqrt(2*pi).*(sigma_voxels)*epsilon)))) + 1;
    n = 1 : hsize;
    center = hsize/2 + 0.5;
    
    sigmai = sigma_voxels(1);
    sigmaj = sigma_voxels(2);
    sigmak = sigma_voxels(3);
    
    keri = zeros(1, 1, hsize, 'single');
    kerj = zeros(1, 1, hsize, 'single');
    kerk = zeros(1, 1, hsize, 'single');
    
    keri(1,1,:) = (1/((2*pi*sigmai.^2).^(1/2))) * exp(-((n - center).^2)/(2*sigmai.^2));
    kerj(1,1,:) = (1/((2*pi*sigmaj.^2).^(1/2))) * exp(-((n - center).^2)/(2*sigmaj.^2));
    kerk(1,1,:) = (1/((2*pi*sigmak.^2).^(1/2))) * exp(-((n - center).^2)/(2*sigmak.^2));
    
    % Normalise
    keri = keri./sum(keri);
    kerj = kerj./sum(kerj);
    kerk = kerk./sum(kerk);
   
    filtered_image = original_image.BlankCopy;
    filtered_image.ChangeRawImage(convn(convn(convn(original_image.RawImage, shiftdim(keri, 2), 'same'), shiftdim(kerj, 1), 'same'), kerk, 'same'));
end








