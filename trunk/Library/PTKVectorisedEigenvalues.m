function [eigvec, eigval] = PTKVectorisedEigenvalues(M, eigenvalues_only)
    % PTKVectorisedEigenvalues. Computes eigenvalues and eigenvectors for many symmetric matrices
    %
    %     PTKVectorisedEigenvalues is similar to Matlab's eigs() function, but can be
    %     used to compute the eigenvalues and eigenvectors for multiple matrices,
    %     which for a large number of points is significantly quicker than using a
    %     for loop. Each input matrix must be symmetric and is represented by a
    %     single row of the input matrix as described below.
    %
    %     The mex function PTKFastEigenvalues is equivalent to function but runs
    %     faster. PTKVectorisedEigenvalues is slower than PTKFastEigenvalues but still
    %     significantly faster than running eigs() in a for loop when a large
    %     number of matrices is involved.
    %
    %
    %         Syntax:
    %             [eigvectors, eigvalues] = PTKFastEigenvalues(M [, eigenvalues_only])
    %
    %         Input:
    %             M is a 6xn matrix. Each column of M represents one 3x3 symmetric matrix as follows
    %
    %                     [V(1) V(2) V(3); V(2) V(4) V(5); V(3) V(5) V(6)]
    % 
    %                 where V is a 6x1 column of M
    % 
    %             eigenvalues_only is an optional parameter which defaults to
    %                 false. Set to true to only calculate eigenvalues and not
    %                 eigenvectors, which reduces the execution time.
    % 
    %          Outputs:
    %              eigenvalues is a 3xn matrix. Each column contains the 3
    %                  eigenvalues of the matrix V described above
    %
    %              eigenvectors is a 3x3xn matrix, where each 3x1 row represents
    %                  an eigenvector (3 for each of the n matrices V described
    %                  above).
    % 
    % 
    % 
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    compute_eigenvectors = true;
    if exist('eigenvalues_only', 'var')
        if (eigenvalues_only)
            compute_eigenvectors = false;
        end
    end

    numvoxels = size(M, 2);
    eigval = zeros(3, numvoxels, 'single');

    m = (M(1,:) + M(4,:) + M(6,:))/3;

    q =  (( M(1,:) - m) .* (M(4,:) - m) .* (M(6,:) - m) + ...
        2 * M(2,:) .* M(5,:) .* M(3,:) - ...
        M(3,:).^2 .* (M(4,:) - m) - ...
        M(5,:).^2 .* (M(1,:) - m) - M(2,:).^2 .* (M(6,:) - m) )/2;

    p = ( ( M(1,:) - m ).^2 + 2 * M(2,:).^2 + 2 * M(3,:).^2 + ...
        ( M(4,:) - m ).^2 + 2 * M(5,:).^2 + ( M(6,:) - m ).^2 )/6;
 
    
    p = max(0.01, p);
    
    phi = 1/3*acos(q./p.^(3/2));
    phi(phi<0) = phi(phi<0)+pi/3;
    
    eigval(1,:) = m + 2*sqrt(p).*cos(phi);
    eigval(2,:) = m - sqrt(p).*(cos(phi) + sqrt(3).*sin(phi));
    eigval(3,:) = m - sqrt(p).*(cos(phi) - sqrt(3).*sin(phi));
    
    [~, i] = sort(abs(eigval));
    i = i + size(eigval,1)*ones(size(eigval,1), 1)*(0:size(eigval, 2) - 1);
    eigval = eigval(i);

    % Only compute the eigenvectors if requested
    if (compute_eigenvectors)
        
        eigvec = zeros(3,3, numvoxels, 'single');
        for l = 1 : 2
            Ai = M(1,:) - eigval(l,:);
            Bi = M(4,:) - eigval(l,:);
            Ci = M(6,:) - eigval(l,:);
            
            eix = ( M(2,:) .* M(5,:) - Bi .* M(3,:) ) .* ( M(3,:) .* M(5,:) - Ci .* M(2,:) );
            eiy = ( M(3,:) .* M(5,:) - Ci .* M(2,:) ) .* ( M(3,:) .* M(2,:) - Ai .* M(5,:) );
            eiz = ( M(2,:) .* M(5,:) - Bi .* M(3,:) ) .* ( M(3,:) .* M(2,:) - Ai .* M(5,:) );
            
            vec = sqrt(eix.^2+eiy.^2+eiz.^2);
            vec = max(0.01, vec);
            eigvec(:,l,:) = [eix; eiy; eiz] ./ vec([1;1;1], :);
        end
        
        eigvec(:,3,:) = cross(eigvec(:,1,:), eigvec(:,2,:));
    else
        eigvec = [];
    end    
end
