function root_branch = PTKLoadTreeFromNodes(file_path, node_filename, element_filename, coordinate_system, template_image, reporting)
    % PTKLoadTreeFromNodes. Load a tree strucure from branches stored in node/element files
    %
    %     Syntax
    %     ------
    %
    %         root_branch = PTKLoadTreeFromNodes(file_path, filename_prefix, reporting)
    %
    %             root_branch     is the root branch in a PTKTreeModel structure 
    %             file_path       is the path where the node and element files
    %                             are to be stored
    %             node_filename   is the name of the node file
    %             edge_filename   is the name of the element file
    %             coordinate_system  a PTKCoordinateSystem enumeration
    %                             specifying the coordinate system to use
    %             template_image  may be required, depending on the value of
    %                             coordinate_system. Provides the required
    %                             parameters for reconstructing the centreline
    %                             tree.
    %             reporting       A PTKReporting or implementor of the same interface,
    %                             for error and progress reporting. Create a PTKReporting
    %                             with no arguments to hide all reporting
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    if nargin < 4
        reporting.Error('PTKLoadTreeFromNodes:BadArguments', 'No coordinate_system parameter specified');
    end
    
    if ~isa(coordinate_system, 'PTKCoordinateSystem')
        reporting.Error('PTKLoadTreeFromNodes:BadArguments', 'coordinate_system parameter is not of type PTKCoordinateSystem');
    end

    node_file = fullfile(file_path, node_filename);
    element_file = fullfile(file_path, element_filename);
    
    % Read node file
    fid = fopen(node_file);

    % First line is the number of nodes
    num_nodes = textscan(fid, '%u', 1);
    num_nodes = num_nodes{1};
    
    % Subsequent lines are node_number, x, y, z, radius, final_node?(y or n)
    node_data = textscan(fid, '%u%f%f%f%f%c', num_nodes, 'Delimiter', ',');
    fclose(fid);
    
    
    % Read element file
    fid = fopen(element_file);
    
    % First line is the number of nodes
    num_elements = textscan(fid, '%u', 1);
    num_elements = num_elements{1};
    
    % Subsequent lines are node_Number, x, y, z, radius, final_node?(y or n)
    element_data = textscan(fid, '%u%u', num_nodes, 'Delimiter', ',');
    fclose(fid);
    
%     tree_branches = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
%     node_points = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    branches = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    
    % Get the tree start point
    start_x = node_data{2}(1);
    start_y = node_data{3}(1);
    start_z = node_data{4}(1);
    radius = node_data{5}(1);
    point_parameters = [];
    point_parameters.Radius = radius;
    
    new_coords_start = PTKImageCoordinateUtilities.ConvertToPTKCoordinates([start_x, start_y, start_z], coordinate_system, template_image);
    first_point = PTKCentrelinePoint(new_coords_start(1), new_coords_start(2), new_coords_start(3), point_parameters);

    % Create a new branch for each node
    for node_index = 2 : num_nodes
        node_number = node_data{1}(node_index);
        end_x = node_data{2}(node_index);
        end_y = node_data{3}(node_index);
        end_z = node_data{4}(node_index);
        radius = node_data{5}(node_index);
        is_end_node = node_data{6}(node_index);
        
        point_parameters = [];
        point_parameters.Radius = radius;
        new_coords_end = PTKImageCoordinateUtilities.ConvertToPTKCoordinates([end_x, end_y, end_z], coordinate_system, template_image);
        last_point = PTKCentrelinePoint(new_coords_end(1), new_coords_end(2), new_coords_end(3), point_parameters);

        new_branch = PTKTreeModel;
        new_branch.Radius = radius;
%         new_branch.Length = branch_length;
%         new_branch.StartPoint = first_point;
        new_branch.EndPoint = last_point;
        new_branch.TemporaryIndex = node_number;
        
        branches(node_number) = new_branch;
    end
    
    % Set up the parent-child relationships. Ignore node zero as this is the
    % root
    for element_index = 1 : length(element_data{1})
        node_a_index = element_data{1}(element_index);
        node_b_index = element_data{2}(element_index);
        if (node_a_index ~= node_b_index) && (node_a_index > 0) && (node_b_index > 0)
            parent_branch = branches(node_a_index);
            child_branch = branches(node_b_index);
            child_branch.SetParent(parent_branch);
        end
    end

    % Set the start point of the first branch
    first_branch = branches(1);
    first_branch.StartPoint = first_point;

    % Set the start point of subsequent branches as the endpoint of the previous
    % branch
    for branch_index = 2 : length(branches)
        branch = branches(branch_index);
        parent_endpoint = branch.Parent.EndPoint;
        start_x = parent_endpoint.CoordX;
        start_y = parent_endpoint.CoordY;
        start_z = parent_endpoint.CoordZ;
        radius = node_data{5}(branch_index);
        point_parameters = [];
        point_parameters.Radius = radius;
        new_coords_start = PTKImageCoordinateUtilities.ConvertToPTKCoordinates([start_x, start_y, start_z], coordinate_system, template_image);
        first_point = PTKCentrelinePoint(new_coords_start(1), new_coords_start(2), new_coords_start(3), point_parameters);
        branch.StartPoint = first_point;
    end
    
    
    root_branch = branches(1);
end