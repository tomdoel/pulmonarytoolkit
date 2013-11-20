function root_branch = PTKLoadTreeFromChaste(file_path, node_filename, edge_filename, template_image, reporting)
    % PTKLoadTreeFromChaste. Load a tree strucure from branches stored in Chaste format node/element files
    %
    %     Syntax
    %     ------
    %
    %         root_branch = PTKLoadTreeFromChaste(file_path, filename_prefix, reporting)
    %
    %             root_branch     is the root branch in a PTKTreeModel structure 
    %             file_path       is the path where the node and edge files
    %                             are to be stored
    %             node_filename   is the node filename
    %             edge_filename   is the filename prefix
    %             template_image  is used to provide a reference coordinate
    %                             system
    %             reporting       A PTKReporting or implementor of the same interface,
    %                             for error and progress reporting. Create a PTKReporting
    %                             with no arguments to hide all reporting
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    node_file = fullfile(file_path, node_filename);
    element_file = fullfile(file_path, edge_filename);
    
    % Read node file
    disp(['node_file:' node_file]);
    fid = fopen(node_file);
    
    % First line is the number of nodes, number of dimensions, number of
    % parameters, number of boundary markers
    param_line = fgetl(fid);
    file_format_params = textscan(param_line, '%u%u%u%u', 1);    
    num_nodes = file_format_params{1};
    space_dims = file_format_params{2};
    num_attributes = file_format_params{3};
    number_boundary_markers = file_format_params{4};
    
    if space_dims ~= 3
        reporting.Error('PTKLoadTreeFromChaste:InvalidDimensions', 'This Chaste model does not have 3 dimensions. I can only load 3D trees.');
    end
    
    node_format_string = ['%u' repmat('%f', 1, space_dims) repmat('%f', 1, num_attributes) repmat('%c', 1, number_boundary_markers)];
    
    % Subsequent lines are node_number, x, y, z, params
    node_data = textscan(fid, node_format_string, num_nodes, 'Delimiter', ',');
    
    fclose(fid);
    
    % Read element file
    fid = fopen(element_file);
    
    % First line is the number of edges, number of boundary markers
    param_line = fgetl(fid);
    file_format_params = textscan(param_line, '%u%u', 1);    
    num_edges = file_format_params{1};
    number_boundary_markers = file_format_params{2};
        
    % Subsequent lines are edge_number, node_1, node_2
    node_format_string = ['%u%u%u' repmat('%c', 1, number_boundary_markers)];
    element_data = textscan(fid, node_format_string, num_edges, 'Delimiter', ',');
    fclose(fid);
    
    node_index = node_data{1};
    x = node_data{2};
    y = node_data{3};
    z = node_data{4};
    ptk_coordinates = PTKImageCoordinateUtilities.CornerToPtkCoordinates([x, y, z], template_image);
    radius = node_data{5};
    node_index_1 = element_data{2};
    node_index_2 = element_data{3};
    
    root_branch = PTKCreateTreeFromNodesAndElements(node_index, ptk_coordinates(:, 1), ptk_coordinates(:, 2), ptk_coordinates(:, 3), radius, node_index_1, node_index_2, reporting);
end