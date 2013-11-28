function PTKVisualiseTreeModel(parent_branch)
    % PTKVisualiseTreeModel. Draws a simplified visualisation of a tree
    %
    %     Syntax
    %     ------
    %
    %         PTKVisualiseTreeModel(parent_branch)
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
    
    % Assumes coordinates are in mm so no voxel size conversion required
    aspect_ratio = [1, 1, 1];
    
    % Set up appropriate figure properties
    fig = figure; 
    set(fig, 'Name', 'Ideal model');
    
    hold on;
    axis off;
    axis square;
    lighting gouraud;
    axis equal;
    set(gcf, 'Color', 'white');
    set(gca, 'DataAspectRatio', aspect_ratio);
    rotate3d;
    cm = colormap('Lines');
    view(-37.5, 30);
    cl = camlight('headlight');
    
    branches = parent_branch.GetBranchesAsList;
    
    for branch = branches
        start_point = branch.StartPoint;
        end_point = branch.EndPoint;
        radius = branch.Radius;
        thickness = 4*radius;
        parent = branch.Parent;
        if isempty(parent)
            x_a = start_point.CoordX;
            y_a = start_point.CoordY;
            z_a = - start_point.CoordZ;
        else
            x_a = parent.EndPoint.CoordX;
            y_a = parent.EndPoint.CoordY;
            z_a = - parent.EndPoint.CoordZ;
        end
        x_b = end_point.CoordX;
        y_b = end_point.CoordY;
        z_b = - end_point.CoordZ;
        
        px = [x_a; x_b];
        py = [y_a; y_b];
        pz = [z_a; z_b];
        
        plot3(px, py, pz, 'b', 'LineWidth', thickness);
    end
end