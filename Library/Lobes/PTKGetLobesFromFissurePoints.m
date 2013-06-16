function result = PTKGetLobesFromFissurePoints(approximant_indices, lung_mask, reporting)
    % PTKGetLobesFromFissurePoints. Generates a lobar segmentation given fissure points.
    %
    %     PTKGetLobesFromFissurePoints is an intermediate stage in segmenting the
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
    
    result = PTKDivideVolumeUsingScatteredPoints(lung_mask, approximant_indices, reporting);
end