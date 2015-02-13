function figure_handle = PTKVisualiseTreeModelCentreline(parent_branch, voxel_size, centreline_only, hide_nodes)
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
    cm = colormap(PTKSoftwareInfo.Colormap);
    view(-37.5, 30);
    cl = camlight('headlight');
    
    branches = parent_branch.GetBranchesAsList;
    
    for branch = branches
        radius = [];
        if ~centreline_only
            radius = branch.Radius;
        end
        
        if isempty(radius)
            if isempty(branch.SmoothedCentreline)
                branch.GenerateSmoothedCentreline;
            end
            
            smoothed_centreline = branch.SmoothedCentreline;
            x_smoothed = [smoothed_centreline.CoordX];
            y_smoothed = [smoothed_centreline.CoordY];
            z_smoothed = [smoothed_centreline.CoordZ];
            
            if ~isempty(branch.Parent)
                x_smoothed = [branch.Parent.Centreline(end).CoordX(end), x_smoothed];
                y_smoothed = [branch.Parent.Centreline(end).CoordY(end), y_smoothed];
                z_smoothed = [branch.Parent.Centreline(end).CoordZ(end), z_smoothed];
            end
            
            if hide_nodes
                plot3(x_smoothed', y_smoothed', z_smoothed', 'b', 'LineWidth', 3);
            else
                plot3(x_smoothed', y_smoothed', z_smoothed', 'ro');
            end
        else
            centreline = branch.Centreline;
            x_coords = [centreline.CoordX];
            y_coords = [centreline.CoordY];
            z_coords = [centreline.CoordZ];
            
            plot3(x_coords', y_coords', z_coords', 'b', 'LineWidth', 4*radius);
            plot3(x_coords', y_coords', z_coords', 'rx');
        end

    end
    
    % Change camera angle
    campos([200, -1600, 0]);

end