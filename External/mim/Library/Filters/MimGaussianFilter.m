function filtered_image = MimGaussianFilter(original_image, filter_size_mm, border_correction)
    % MimGaussianFilter. Performs 3D Gaussian filtering on a 3D image.
    %
    %     MimGaussianFilter takes in an image in a PTKImage class and performs 3D
    %     Gaussian filtering. The sigma size is specified in mm; this function
    %     takes into account the voxel size.
    %
    %     The input and output images are of class PTKImage.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if nargin < 3
        border_correction = false;
    end
    
    if ~isa(original_image, 'PTKImage')
        error('MimGaussianFilter requires a PTKImage as input');
    end
    
    voxel_size_mm = original_image.VoxelSize;
    sigma_mm = filter_size_mm;
    
    epsilon = 1e-3;
    sigma_voxels = sigma_mm./voxel_size_mm;
    border_region = max(ceil((sigma_voxels).*sqrt(-2*log(sqrt(2*pi).*(sigma_voxels)*epsilon))));
    hsize = 2*border_region + 1;
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
    
    % Shift the image so zero is the minimum, because the convolution uses
    % zero-padding
    raw_image = single(original_image.RawImage);
    
    intensity_offset = min(raw_image(:));
    raw_image = raw_image - intensity_offset;
    raw_image = convn(convn(convn(raw_image, shiftdim(keri, 2), 'same'), shiftdim(kerj, 1), 'same'), kerk, 'same');
    raw_image = raw_image + intensity_offset;
    
    if border_correction
        raw_image(1:border_region, :, :) = original_image.RawImage(1:border_region, :, :);
        raw_image(end-border_region+1:end, :, :) = original_image.RawImage(end-border_region+1:end, :, :);
        raw_image(:, 1:border_region, :) = original_image.RawImage(:, 1:border_region, :);
        raw_image(:, end-border_region+1:end, :) = original_image.RawImage(:, end-border_region+1:end, :);
        raw_image(:, :, 1:border_region) = original_image.RawImage(:, :, 1:border_region);
        raw_image(:, :, end-border_region+1:end) = original_image.RawImage(:, :, end-border_region+1:end);
    end
    filtered_image.ChangeRawImage(raw_image);
end








