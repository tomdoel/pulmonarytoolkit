function figure_handle = PTKVisualiseTreeModelCentreline(parent_branch, voxel_size, centreline_only)
    % PTKVisualiseTreeModelCentreline. Draws a simplified visualisation of a tree centreline
    %
    %     Syntax
    %     ------
    %
    %         PTKVisualiseTreeModelCentreline(parent_branch)
    %
    %             parent_branch     is the root branch in a PTKTreeModel structure 
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %           
    %
    
    if nargin < 3
        centreline_only = false;
    end
    
    aspect_ratio = [1/voxel_size(2), 1/voxel_size(1), 1/voxel_size(3)];
    
    % Set up appropriate figure properties
    figure_handle = figure; 
    set(figure_handle, 'Name', 'Centreline');
    
    hold on;
    axis off;
    axis square;
    lighting gouraud;
    axis equal;
    set(gcf, 'Color', 'white');
    daspect(aspect_ratio);
    rotate3d;
    cm = colormap('Lines');
    view(-37.5, 30);
    cl = camlight('headlight');
    
    branches = parent_branch.GetBranchesAsList;
    
    for branch = branches
        centreline = branch.Centreline;

        radius = branch.Radius;
        if centreline_only
            radius = [];
        end
        
        x_coords = [centreline.CoordJ];
        y_coords = [centreline.CoordI];
        z_coords = [centreline.CoordK];
        
        if isempty(radius)
            branch.GenerateSmoothedCentreline;
            smoothed_centreline = branch.SmoothedCentreline;
            x_smoothed = [smoothed_centreline.CoordJ];
            y_smoothed = [smoothed_centreline.CoordI];
            z_smoothed = [smoothed_centreline.CoordK];
            
            plot3(x_smoothed', y_smoothed', -z_smoothed', 'b', 'LineWidth', 1.5);
        else
            plot3(x_coords', y_coords', z_coords', 'b', 'LineWidth', 4*radius);
        end

    end
    
    % Change camera angle
    campos([200, -1600, 0]);

end

function value = GenerateSpline(knots, num_points)
    knots_add=zeros(size(knots, 1) + 2, size(knots, 2));
    knots_add(2 : size(knots, 1) + 1, :) = knots;
    knots_add(1, :) = knots_add(2, :) - (knots_add(3, :) - knots_add(2, :));
    knots_add(end, :) = knots_add(end - 1, :) - (knots_add(end - 2, : ) - knots_add(end - 1, :));
    
    total_knots = size(knots_add, 1);
    inter_values = 0 : 1/num_points : 1;
    inter_values2 = inter_values.^2;
    inter_values3 = inter_values.^3;

    for index = 2 : total_knots-2
        coeffs = (1/6).*[knots_add(index - 1,:) + 4*knots_add(index, :)+knots_add(index + 1, :); ...
                    - 3*knots_add(index - 1, :) + 3*knots_add(index + 1, :); ...
                    3*knots_add(index - 1, :) - 6*knots_add(index, :) + 3*knots_add(index + 1, :); ...
                    - knots_add(index - 1, :) + 3*knots_add(index, :) - 3*knots_add(index + 1, :) + knots_add(index+2, :)]';
            
        interv = [ones(size(inter_values)); inter_values; inter_values2; inter_values3];
        value(:, (index - 2)*num_points + 1:(index - 1)*num_points + 1) = coeffs*interv;
    end
end