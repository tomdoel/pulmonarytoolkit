function TDVisualiseTreeModelCentreline(parent_branch, voxel_size)
    % TDVisualiseTreeModelCentreline. Draws a simplified visualisation of a tree centreline
    %
    %     Syntax
    %     ------
    %
    %         TDVisualiseTreeModelCentreline(parent_branch)
    %
    %             parent_branch     is the root branch in a TDTreeModel structure 
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %           
    %     
    
    aspect_ratio = [1/voxel_size(2), 1/voxel_size(1), 1/voxel_size(3)];
    
    % Set up appropriate figure properties
    fig = figure; 
    set(fig, 'Name', 'Centreline');
    
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
        
        x_coords = [centreline.CoordJ];
        y_coords = [centreline.CoordI];
        z_coords = [centreline.CoordK];
        
        plot3(x_coords', y_coords', z_coords', 'b', 'LineWidth', 4*radius);

    end
end