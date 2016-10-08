function filtered_image = PTKGaussianFilter(original_image, filter_size_mm, border_correction)
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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if nargin < 3
        border_correction = false;
    end
    
    if ~isa(original_image, 'PTKImage')
        error('PTKGaussianFilter requires a PTKImage as input');
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
        border_image = original_image.BlankCopy;
        
        % Create a mask image defining voxels where the filtered values
        % will be replaced with the original values. This deals with border
        % voxels that would otherwise be smoothed by the filtering
        border_image_raw = false(original_image.ImageSize);

        % Add a border around the image
        border_image_raw(1:border_region, :, :) = true;
        border_image_raw(end-border_region+1:end, :, :) = true;
        border_image_raw(:, 1:border_region, :) = true;
        border_image_raw(:, end-border_region+1:end, :) = true;
        border_image_raw(:, :, 1:border_region) = true;
        border_image_raw(:, :, end-border_region+1:end) = true;
        
        % Add in padding values if there are any
        if ~isempty(original_image.PaddingValue)
            border_image_raw(original_image.RawImage == original_image.PaddingValue) = true;
        end
        
        border_image.ChangeRawImage(border_image_raw);
        
        % This is the region over which the filter will not be applied
        border_image.BinaryMorph(@imdilate, filter_size_mm./voxel_size_mm);
        
        raw_image(border_image.RawImage(:)) = original_image.RawImage(border_image.RawImage(:));
        
    end
    filtered_image.ChangeRawImage(raw_image);
end








