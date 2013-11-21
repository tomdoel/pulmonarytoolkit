function results = PTKDrawAirwayGrowingBranchesAsSegmentation(airway_tree, template_image, reporting)
    % PTKDrawAirwayGrowingBranchesAsSegmentation. Creates a segmentation image
    %     based on the centreline of an airway growing tree
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    results = template_image;
    num_branches = airway_tree.CountBranches;
    results_raw = zeros(results.ImageSize, 'uint8');
    
    reporting.UpdateProgressMessage('Drawing branches');
    
    branches_to_do = airway_tree;
    
    all_starts = zeros(num_branches, 3);
    all_ends = zeros(num_branches, 3);
    index = 1;
    
    while ~isempty(branches_to_do)
        branch = branches_to_do(end);
        branches_to_do(end) = [];
        children = branch.Children;
        if ~isempty(children)
            branches_to_do = [branches_to_do, children];
        end
        
        parent = branch.Parent;
        
        if isempty(parent)
            start_point_mm = branch.StartCoords;
        else
            start_point_mm = parent.EndCoords;
        end
        end_point_mm = branch.EndCoords;
        if isnan(end_point_mm)
            disp('*');
        end
        
        all_starts(index, :) = start_point_mm;
        all_ends(index, :) = end_point_mm;
        
        index = index + 1;
    end

    all_starts_coords = template_image.CoordinatesMmToGlobalCoordinates(all_starts);
    all_starts_coords = template_image.GlobalToLocalCoordinates(all_starts_coords);
    all_ends_coords = template_image.CoordinatesMmToGlobalCoordinates(all_ends);
    all_ends_coords = template_image.GlobalToLocalCoordinates(all_ends_coords);

    
    for index = 1 : num_branches
        start_point_coordinates = all_starts_coords(index, :);
        end_point_coordinates = all_ends_coords(index, :);
        
        lengths = end_point_coordinates - start_point_coordinates;
        num_points = 1 + ceil(max(abs(lengths)));
        
        span_i = linspace(start_point_coordinates(1), end_point_coordinates(1), num_points);
        span_j = linspace(start_point_coordinates(2), end_point_coordinates(2), num_points);
        span_k = linspace(start_point_coordinates(3), end_point_coordinates(3), num_points);
        
        local_coordinates = round([span_i', span_j', span_k']);
        local_indices = PTKImageCoordinateUtilities.FastSub2ind(template_image.ImageSize, local_coordinates(:, 1), local_coordinates(:, 2), local_coordinates(:, 3));
        results_raw(local_indices) = 1;
    end
    
    results.ChangeRawImage(results_raw);
    results.ImageType = PTKImageType.Colormap;
end
