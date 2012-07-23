function results = TDGetCentrelineFromAirways(lung_image, airway_results, reporting)
    % TDGetCentrelineFromAirways. Computes the centreline and radius for a
    % segmented airway tree.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    airway_segented_image = TDGetImageFromAirwayResults(airway_results, lung_image, reporting);
    
    
    reporting.ShowProgress('Finding airways');
    
    start_point = airway_results.StartPoint;
    start_point_index = sub2ind(airway_results.ImageSize, start_point(1), start_point(2), start_point(3));
    
    
    start_point_local = airway_segented_image.GlobalToLocalCoordinates(start_point);
    end_points = airway_results.EndPoints;
    fixed_points = [start_point_index, end_points];
    
    % No need for this line since the image from TDGetImageFromAirwayResults
    % does not include exploded points
    %             airway_segented_image.ChangeRawImage(uint8(airway_segented_image.RawImage == 1));
    
    % While each branch of the tree has been closed, there may still be
    % holes where branches meet. Hence we perform a hole filling to
    % ensure this does not cause topoligcal problems with the
    % skeletonisation
    reporting.ShowProgress('Filling holes in airway tree');
    airway_segented_image = TDFillHolesInImage(airway_segented_image);
    
    % Skeletonise
    reporting.ShowProgress('Reducing airways to a skeleton');
    skeleton_image = TDSkeletonise(airway_segented_image, fixed_points, reporting);
    
    % The final processing removes closed loops and sorts the skeleton
    % points into a tree strcuture
    reporting.ShowProgress('Processing skeleton tree');
    skeleton_results = TDProcessAirwaySkeleton(skeleton_image.RawImage, start_point_local, reporting);
    skeleton_results.airway_skeleton.RecomputeGenerations(1);
    
    % Compute radius for each branch
    dt_image = airway_segented_image.RawImage;
    dt_image = dt_image == 0;
    dt_image = bwdist(dt_image);
    [radius_results, skeleton_tree] = GetRadius(lung_image, skeleton_results.airway_skeleton, dt_image);
    skeleton_tree_model = TDTreeModel.CreateFromSkeletonTree(skeleton_tree, lung_image);
    
    
    results = [];
    results.AirwayCentrelineTree = skeleton_tree_model;
    results.OriginalSkeletonPoints = skeleton_results.original_skeleton_points;
    results.BifurcationPoints = skeleton_results.bifurcation_points;
    results.SkeletonPoints = skeleton_results.skeleton_points;
    results.ImageSize = skeleton_results.image_size;
    results.StartPoint = skeleton_results.start_point;
    results.RemovedPoints = skeleton_results.removed_points;
    
end

function [results, airway_skeleton] = GetRadius(lung_image, airway_skeleton, dt_image)
    segments_to_do = airway_skeleton;
    results = {};
    
    while ~isempty(segments_to_do)
        next_segment = segments_to_do(end);
        segments_to_do(end) = [];
        segments_to_do = [segments_to_do next_segment.Children];
        
        next_result = TDComputeRadiusForBranch(next_segment, lung_image, dt_image);
        results{end+1} = next_result;
        
        next_segment.Radius = next_result.Radius;
        
    end
end

