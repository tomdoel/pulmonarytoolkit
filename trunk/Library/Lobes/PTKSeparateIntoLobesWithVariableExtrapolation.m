function [lobes_raw, fissure_plane] = PTKSeparateIntoLobesWithVariableExtrapolation(max_fissure_points, lung_mask, image_size, volume_fraction_threshold, reporting)
    % PTKSeparateIntoLobesWithVariableExtrapolation.
    %
    %     PTKSeparateIntoLobesWithVariableExtrapolation is an intermediate stage in segmenting the
    %     lobes. It is not intended to be a general-purpose algorithm.    
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

    start_extrapolation = 4;
    max_extrapolation = 20;
    
    extrapolation = start_extrapolation;
    
    compute_again = true;
    
    while compute_again
        fissure_plane = 3*PTKGetFissurePlane(max_fissure_points, image_size, extrapolation);
        fissure_plane_indices = find(fissure_plane == 3);
        
        % Create a mask which excludes the lower lobe
        lobes_raw = PTKGetLobesFromFissurePoints(fissure_plane_indices, lung_mask, volume_fraction_threshold, reporting);
        
        % If the lobe separation fails, then try a larger extrapolation
        if isempty(lobes_raw)
            extrapolation = extrapolation + 2;
            if extrapolation > max_extrapolation
                reporting.Error('PTKFissurePlane:UnableToDivide', 'Could not separate the lobes');
            end
            compute_again = true;
        else
            compute_again = false;
        end
    end
end
