function kernel = PTKNormalisedGaussianKernel(voxel_size_mm, filter_size_mm, minimum_grid_size_mm)
    % PTKNormalisedGaussianKernel.
    %
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
    
    if nargin < 3
        minimum_grid_size_mm = [];
    end

    if numel(minimum_grid_size_mm) == 1
        minimum_grid_size_mm = repmat(minimum_grid_size_mm, [1, 3]);
    end
    
    sigma_mm = filter_size_mm;
    
    epsilon = 1e-3;
    sigma_voxels = sigma_mm./voxel_size_mm;
    grid_size = 2*(ceil((sigma_voxels).*sqrt(-2*log(sqrt(2*pi).*(sigma_voxels)*epsilon)))) + 1;
    
    if ~isempty(minimum_grid_size_mm)
        minimum_grid_size = 2*(ceil((minimum_grid_size_mm./voxel_size_mm)/2));
        grid_size = max(grid_size, minimum_grid_size);
    end
    
    grid_size_i = grid_size(1);
    grid_size_j = grid_size(2);
    grid_size_k = grid_size(3);
    
    center_i = grid_size_i/2 + 0.5;
    center_j = grid_size_j/2 + 0.5;
    center_k = grid_size_k/2 + 0.5;
    
    n_i = 1 : grid_size_i;
    n_j = 1 : grid_size_j;
    n_k = 1 : grid_size_k;
    
    sigmai = sigma_voxels(1);
    sigmaj = sigma_voxels(2);
    sigmak = sigma_voxels(3);
    
    keri = zeros(1, 1, grid_size_i, 'single');
    kerj = zeros(1, 1, grid_size_j, 'single');
    kerk = zeros(1, 1, grid_size_k, 'single');
    
    keri(1,1,:) = (1/((2*pi*sigmai.^2).^(1/2))) * exp(-((n_i - center_i).^2)/(2*sigmai.^2));
    kerj(1,1,:) = (1/((2*pi*sigmaj.^2).^(1/2))) * exp(-((n_j - center_j).^2)/(2*sigmaj.^2));
    kerk(1,1,:) = (1/((2*pi*sigmak.^2).^(1/2))) * exp(-((n_k - center_k).^2)/(2*sigmak.^2));
    
    % Normalise
    keri = keri./sum(keri);
    kerj = kerj./sum(kerj);
    kerk = kerk./sum(kerk);
   
    ker1 = repmat(shiftdim(keri, 2), 1, grid_size_j, grid_size_k);
    ker2 = repmat(shiftdim(kerj, 1), grid_size_i, 1, grid_size_k);
    ker3 = repmat(kerk, grid_size_i, grid_size_j, 1);
    kernel = ker1.*ker2.*ker3;
    
    kernel = kernel/max(kernel(:));
end