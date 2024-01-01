function vesselness_wrapper = PTKComputeVesselnessFromHessianeigenvalues(hessian_eigs_wrapper, voxel_size)
    % PTKComputeVesselnessFromHessianeigenvalues. Vesselness filter for detecting blood vessels
    %
    %     PTKComputeVesselnessFromHessianeigenvalues computes a mutiscale
    %     vesselness filter based on Frangi et al., 1998. "Multiscale Vessel
    %     Enhancement Filtering". The filter returns a value at each point which
    %     in some sense representes the probability of that point belonging to a
    %     blood vessel.
    %
    %     This function takes in a PTKWraper object which can either contain a nx6
    %     matrix containing the 3 Hessian matrix eigenvalues for each of n
    %     points, or it can be an ixjxkx3 matrix representing the 3 Hessian
    %     matrix eigenvalues for an image of dimension ixjxk.
    %
    %     The output is a single vesselness value for each input point.
    %
    %     See the PTKVesselness plugin for example usage.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    % lam1 = smallest eigenvalue, lam3 = largest eigenvalue
    
    vesselness_wrapper = CoreWrapper();
    
    % The input matrix could be a linear set of points, or an image matrix
    if ndims(hessian_eigs_wrapper.RawImage) == 2
        lam1 = hessian_eigs_wrapper.RawImage(:, 1); % smallest
        lam2 = hessian_eigs_wrapper.RawImage(:, 2);
        lam3 = hessian_eigs_wrapper.RawImage(:, 3); % biggest
    else
        lam1 = hessian_eigs_wrapper.RawImage(:,:,:,1); % smallest
        lam2 = hessian_eigs_wrapper.RawImage(:,:,:,2);
        lam3 = hessian_eigs_wrapper.RawImage(:,:,:,3); % biggest
    end
    
    term_1 = abs(lam2./lam3); % Ra
    alpha = 0.5;
    term_1 = 1 - exp((-term_1.^2)./(2*alpha^2));
        
    term_2 = abs(lam1)./sqrt(abs(lam2.*lam3)); % Rb
    beta = 0.5;
    term_2 = exp((-term_2.^2)./(2*beta^2));

    term_3 = sqrt(lam1.^2 + lam2.^2 + lam3.^2); % S
    
    % Frangi et al. choose a noise threshold based on the Hessian mean.
    % However, we find a fixed experimentally-chosen threshold works better, but
    % this must be scaled by the voxel size
    multiple_matrix = voxel_size'*voxel_size;
    c_scaling = 1/mean(multiple_matrix(:));
    c = 400*c_scaling;
    
    term_3 = 1 - exp((-term_3.^2)./(2*c^2));
    
    check_signs = (lam2 <= 0) & (lam3 <= 0);

    vesselness_wrapper.RawImage = term_1.*term_2.*term_3.*check_signs;
end
