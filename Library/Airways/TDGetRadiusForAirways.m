function results = TDGetRadiusForAirways(centreline_results, lung_image, radius_approximation, reporting, figure_airways_3d)
    % TDGetRadiusForAirways. Computes the radius for a segmented airway tree.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    reporting.ShowProgress('Computing radius for each branch');
    
    
    [radius_results, skeleton_tree] = GetRadius(lung_image, centreline_results.IntermediateAirwaySkeleton, radius_approximation, reporting, figure_airways_3d);
    centreline_tree_model = TDTreeModel.CreateFromSkeletonTree(skeleton_tree, lung_image);
    
    results = rmfield(centreline_results, 'IntermediateAirwaySkeleton');
    results.AirwayCentrelineTree = centreline_tree_model;
end
    
function [results, airway_skeleton] = GetRadius(lung_image, airway_skeleton, radius_approximation, reporting, figure_airways_3d)
    segments_to_do = airway_skeleton;
    results = {};
    
    number_of_segments = airway_skeleton.CountBranches;
    segments_done = 0;
    
    lung_image_as_double = lung_image.BlankCopy;
    lung_image_as_double.ChangeRawImage(double(lung_image.RawImage));
    
    while ~isempty(segments_to_do)
        reporting.UpdateProgressValue(round(100*segments_done/number_of_segments));
        segments_done = segments_done + 1;
        next_segment = segments_to_do(end);
        segments_to_do(end) = [];
        segments_to_do = [segments_to_do next_segment.Children];
        
        next_result = TDComputeRadiusForBranch(next_segment, lung_image_as_double, radius_approximation, figure_airways_3d);
        results{end+1} = next_result;
        
        next_segment.Radius = next_result.Radius;
        
    end
end

