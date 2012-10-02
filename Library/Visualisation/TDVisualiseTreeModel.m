function TDVisualiseTreeModel(parent_branch)
    % TDVisualiseTreeModel. Draws a simplified visualisation of a tree
    %
    %     Syntax
    %     ------
    %
    %         TDVisualiseTreeModel(parent_branch)
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
            x_a = start_point.CoordJ;
            y_a = start_point.CoordI;
            z_a = - start_point.CoordK;
        else
            x_a = parent.EndPoint.CoordJ;
            y_a = parent.EndPoint.CoordI;
            z_a = - parent.EndPoint.CoordK;            
        end
        x_b = end_point.CoordJ;
        y_b = end_point.CoordI;
        z_b = - end_point.CoordK;
        
        px = [x_a; x_b];
        py = [y_a; y_b];
        pz = [z_a; z_b];
        
        plot3(px, py, pz, 'b', 'LineWidth', thickness);
    end
end