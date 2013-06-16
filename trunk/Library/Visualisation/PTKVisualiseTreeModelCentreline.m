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
        skip = 3;
        x_coords = [centreline.CoordJ];
        y_coords = [centreline.CoordI];
        z_coords = [centreline.CoordK];
        
        num_points = numel(x_coords);
        if branch.GenerationNumber > 3
            range = round(linspace(1, num_points, 3));
        else
            range = round(linspace(1, num_points, 10));
        end
        
        x_coords_reduced = x_coords(range);
        y_coords_reduced = y_coords(range);
        z_coords_reduced = z_coords(range);
        
        if isempty(radius)
            knot = [x_coords_reduced', y_coords_reduced', z_coords_reduced'];
            
            % Generate a spline curve through the centreline points
            % Currently this is not used in the radius computation
            spline = GenerateSpline(knot, 2);
            
            plot3(spline(1,:)', spline(2,:)', -spline(3,:)', 'b', 'LineWidth', 1.5);
            if ~isempty(branch.Parent)
                p_x_coords = [branch.Parent.Centreline.CoordJ];
                p_y_coords = [branch.Parent.Centreline.CoordI];
                p_z_coords = [branch.Parent.Centreline.CoordK];
                xb_coords = [p_x_coords(end), x_coords(1)];
                yb_coords = [p_y_coords(end), y_coords(1)];
                zb_coords = [p_z_coords(end), z_coords(1)];
                plot3(xb_coords', yb_coords', -zb_coords', 'b', 'LineWidth', 1.5);
            end
        else
            plot3(figure_handle, x_coords', y_coords', z_coords', 'b', 'LineWidth', 4*radius);
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