function result = PTKGetFissurePlane(max_fissure_points, image_size, extrapolation_multiple)
    % PTKGetFissurePlane. Generates fissure curves given candidate points
    %
    %     PTKGetFissurePlane is an intermediate stage in segmenting the
    %     lobes.
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
    
    high_fissure_indices = max_fissure_points;
    approximant_indices = GetModelIndices(high_fissure_indices, image_size, extrapolation_multiple);
    
    result = zeros(image_size, 'uint8');
    result(:) = 0;
     result(approximant_indices) = 1;
    
end

function model_indices = GetModelIndices(candidate_indices, image_size, extrapolation_multiple)
    [x, y, z] = ind2sub(image_size, candidate_indices);    
    X = [x, y, z]';    

    PARAM = 'pca';
    INTERP = 'mbae';

    RES = [0.5, 0.5];
    KLIM = extrapolation_multiple;

    nlev = 5;
    
    [XI, ~, ~, ~] = surface_interpolation(X, PARAM, INTERP, RES, KLIM, nlev);
    
    XI = round(XI);
    valid_indices = XI(:,1) > 0 & XI(:,2) > 0 & XI(:,3) > 0 & XI(:,1) <= image_size(1) & XI(:,2) <= image_size(2) & XI(:,3) <= image_size(3);
    XI = XI(valid_indices, :);
    model_indices = sub2ind(image_size, XI(:, 1), XI(:, 2), XI(:, 3));
    
end