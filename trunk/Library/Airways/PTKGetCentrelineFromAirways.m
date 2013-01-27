function results = PTKGetCentrelineFromAirways(airway_results, template_image, reporting)
    % PTKGetCentrelineFromAirways. Computes the centreline and radius for a
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
    
    airway_segmented_image = PTKGetImageFromAirwayResults(airway_results.AirwayTree, template_image, false, reporting);

    reporting.ShowProgress('Finding airways');
    
    start_point_global = airway_results.StartPoint;
    start_point_index = sub2ind(airway_results.ImageSize, start_point_global(1), start_point_global(2), start_point_global(3));
    
    
    start_point_local = airway_segmented_image.GlobalToLocalCoordinates(start_point_global);
    end_points = airway_results.EndPoints;
    fixed_points = [start_point_index, end_points];
    
    % No need for this line since the image from PTKGetImageFromAirwayResults
    % does not include exploded points
    %             airway_segented_image.ChangeRawImage(uint8(airway_segented_image.RawImage == 1));
    
    % While each branch of the tree has been closed, there may still be
    % holes where branches meet. Hence we perform a hole filling to
    % ensure this does not cause topoligcal problems with the
    % skeletonisation
    reporting.ShowProgress('Filling holes in airway tree');
    airway_segmented_image = PTKFillHolesInImage(airway_segmented_image);
    
    % Skeletonise
    reporting.ShowProgress('Reducing airways to a skeleton');
    skeleton_image = PTKSkeletonise(airway_segmented_image, fixed_points, reporting);
    
    % The final processing removes closed loops and sorts the skeleton
    % points into a tree strcuture
    reporting.ShowProgress('Processing skeleton tree');
    skeleton_results = PTKProcessAirwaySkeleton(skeleton_image.RawImage, start_point_local, reporting);
    skeleton_results.airway_skeleton.RecomputeGenerations(1);
    
    results = [];
    results.IntermediateAirwaySkeleton = skeleton_results.airway_skeleton;
    results.OriginalCentrelinePoints = skeleton_image.LocalToGlobalIndices(skeleton_results.original_skeleton_points);
    results.BifurcationPoints = skeleton_image.LocalToGlobalIndices(skeleton_results.bifurcation_points);
    results.CentrelinePoints = skeleton_image.LocalToGlobalIndices(skeleton_results.skeleton_points);
    results.ImageSize = template_image.OriginalImageSize;
    results.StartPoint = start_point_global;
    results.RemovedPoints = skeleton_image.LocalToGlobalIndices(skeleton_results.removed_points);
end