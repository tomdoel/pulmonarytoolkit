function start_branches = PTKReallocateAirwaysByLobe(start_branches, lobes, reporting)
    % PTKReallocateAirwaysByLobe. Given a segmented airway tree and lobar
    %     segmentations, finds the bronchus corresponding to each pulmonary lobe
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    uncertain_bronchi = start_branches.LeftUncertain;
    for bonchus = uncertain_bronchi
        indices = GetVoxelsForTheseBranches(bonchus, lobes);
        lobe_values = lobes.RawImage(indices);
        lobe_values = setdiff(lobe_values, 0);
        if ~isempty(lobe_values)
            which_lobe = mode(single(lobe_values));
            switch which_lobe
                case 1
                    start_branches.RightUpper = [start_branches.RightUpper bonchus];
                case 2
                    start_branches.RightMid = [start_branches.RightMid bonchus];
                case 4
                    start_branches.RightLower = [start_branches.RightLower bonchus];
                case 5
                    start_branches.LeftUpper = [start_branches.LeftUpper bonchus];
                case 6
                    start_branches.LeftLower = [start_branches.LeftLower bonchus];
            end
            start_branches.LeftUncertain = setdiff(start_branches.LeftUncertain, bonchus);
        end
    end
end

function voxels = GetVoxelsForTheseBranches(start_indices, template)
    voxels = [];
    for index = 1 : numel(start_indices)
        voxels = cat(2, voxels, CentrelinePointsToLocalIndices(start_indices(index).GetCentrelineTree, template));
    end
end

function centreline_indices_local = CentrelinePointsToLocalIndices(centreline_points, template_image)
    centreline_indices_global = [centreline_points.GlobalIndex];
    centreline_indices_local = template_image.GlobalToLocalIndices(centreline_indices_global);
end
