function fissureness_wrapper = PTKComputeFissurenessFromHessianeigenvalues(hessian_eigs_wrapper)
    % PTKComputeFissurenessFromHessianeigenvalues. Filter for detecting fissures.
    %
    %     PTKComputeFissurenessFromHessianeigenvalues computes a 
    %     fissureness filter based on Doel et al., 2012. "Pulmonary lobe
    %     segmentation from CT images using fissureness, airways, vessels and
    %     multilevel B-splines". The filter returns a value at each point which
    %     in some sense representes the probability of that point belonging to a
    %     fissure.
    %
    %     This function takes in a PTKWraper object which can either contain a nx6
    %     matrix containing the 3 Hessian matrix eigenvalues for each of n
    %     points, or it can be an ixjxkx3 matrix representing the 3 Hessian
    %     matrix eigenvalues for an image of dimension ixjxk.
    %
    %     The output is a single vesselness value for each input point.
    %
    %     See the PTKFissurenessHessianFactor plugin for example usage.
    %
    %     For more information, see
    %     [Doel et al., Pulmonary lobe segmentation from CT images using
    %     fissureness, airways, vessels and multilevel B-splines, 2012]
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    % lam1 = smallest eigenvalue, lam3 = largest eigenvalue
    fissureness_wrapper = PTKWrapper;

    % This allows us to compute the Fissureness in a vectorised or matrix-based way
    if ndims(hessian_eigs_wrapper.RawImage) == 2
        lam1 = hessian_eigs_wrapper.RawImage(:, 1); % smallest
        lam2 = hessian_eigs_wrapper.RawImage(:, 2);
        lam3 = hessian_eigs_wrapper.RawImage(:, 3); % biggest
    else
        lam1 = hessian_eigs_wrapper.RawImage(:,:,:,1); % smallest
        lam2 = hessian_eigs_wrapper.RawImage(:,:,:,2);
        lam3 = hessian_eigs_wrapper.RawImage(:,:,:,3); % biggest
    end
    
    % Suppress points with positive largest eigenvalue
    capital_gamma = (lam3 < 0);
    
    % Sheetness (Descoteaux et al, 2005)
    R_plane = abs(lam2./lam3);
    alpha = 0.5;
    F_plane = exp((-R_plane.^2)./(2*alpha^2));

    % Suppress signals from vessel walls
    R_wall = sqrt(lam1.^2 + lam2.^2);    
    w = 3; % soft threshold. Consider e.g. hessian_norm/2
    F_wall = exp((-abs(R_wall).^2)./(2*w^2));

    % Fissureness calculation
    fissureness_wrapper.RawImage = 100*capital_gamma.*F_plane.*F_wall;
end
