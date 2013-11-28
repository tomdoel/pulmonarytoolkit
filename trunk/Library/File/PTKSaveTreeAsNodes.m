function PTKSaveTreeAsNodes(tree_root, file_path, filename_prefix, coordinate_system, template_image, reporting)
    % PTKSaveTreeAsNodes. Exports a tree structure into node and element files
    %
    %     Syntax
    %     ------
    %
    %         PTKSaveTreeAsNodes(tree_root, file_path, base_filename, reporting)
    %
    %             tree_root       is the root branch in a PTKTreeModel structure 
    %             file_path       is the path where the node and element files
    %                             are to be stored
    %             filename_prefix is the filename prefix. The node and element
    %                             files will have '_node.txt' and '_element.txt'
    %                             appended to this prefix before saving.
    %             coordinate_system  a PTKCoordinateSystem enumeration
    %                             specifying the coordinate system to use
    %             template_image  A PTKImage providing voxel size and image size
    %                             parameters
    %             reporting       A PTKReporting or implementor of the same interface,
    %                             for error and progress reporting. Create a PTKReporting
    %                             with no arguments to hide all reporting
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    if nargin < 4
        reporting.Error('PTKSaveTreeAsNodes:BadArguments', 'No coordinate_system parameter specified');
    end
    
    if ~isa(coordinate_system, 'PTKCoordinateSystem')
        reporting.Error('PTKSaveTreeAsNodes:BadArguments', 'coordinate_system parameter is not of type PTKCoordinateSystem');
    end
    
    node_file_name = fullfile(file_path, [filename_prefix '_node.txt']);
    element_file_name = fullfile(file_path, [filename_prefix '_element.txt']);
    
    linear_branch_list = tree_root.GetBranchesAsList;
    
    num_branches = length(linear_branch_list);

    % Create the node file (contains the coordinates and radius)
    node_file_handle = fopen(node_file_name, 'w');
    element_file_handle = fopen(element_file_name, 'w');
    
    % The first file entry is the number of nodes
    fprintf(node_file_handle, '%u\r\n', num_branches);
    fprintf(element_file_handle, '%u\r\n', num_branches);
    
    % Create the first node from the trachea start point. The first element
    % connects this point to itself
    first_point = tree_root.StartPoint;
    
    dicom_coordinates = PTKImageCoordinateUtilities.ConvertFromPTKCoordinates([first_point.CoordX, first_point.CoordY, first_point.CoordZ], coordinate_system, template_image);
    start_x_mm = dicom_coordinates(1);
    start_y_mm = dicom_coordinates(2);
    start_z_mm = dicom_coordinates(3);
    
    
    start_radius_mm = tree_root.Radius;
    start_density_mgml = tree_root.Density;
    
    PrintNodeToFile(node_file_handle, 0, start_x_mm, start_y_mm, start_z_mm, start_radius_mm, start_density_mgml, false);
    PrintElementToFile(element_file_handle, 0, 0);
    
    % The first branch in the tree will be converted to a node at its endpoint.
    % We need this to be connected to the first node we created above, so set
    % its parent index to zero, the index of the first node
    linear_branch_list(1).TemporaryIndex = 0;
    current_node_index = 1;    
    
    for branch = linear_branch_list
        parent_node_index = branch.TemporaryIndex;
        
        % Write branch to node file (the end point will be the node coordinate).
        PrintBranchToFileAsNode(node_file_handle, current_node_index, branch, coordinate_system, template_image);
        
        % Write (parent, current_node_index) to element file
        PrintElementToFile(element_file_handle, parent_node_index, current_node_index)
        
        % Set the parent node index for each child branch to be the current branch
        % node index
        if ~isempty(branch.Children)
            for child = branch.Children
                child.TemporaryIndex = current_node_index;
            end
        end
        
        current_node_index = current_node_index + 1;
    end
    
    % Close the files
    fclose(node_file_handle);
    fclose(element_file_handle);
    
end
   
    

function PrintElementToFile(fid, parent_index, child_index)
    fprintf(fid, '%u,%u\r\n', parent_index, child_index);
end

function PrintBranchToFileAsNode(fid, node_index, branch, coordinate_system, template_image)

    % We define nodes using the end coordinate of each branch, since this is the
    % bifurcation point
    last_point = branch.EndPoint;
    
    dicom_coordinates = PTKImageCoordinateUtilities.ConvertFromPTKCoordinates([last_point.CoordX, last_point.CoordY, last_point.CoordZ], coordinate_system, template_image);
    x_mm = dicom_coordinates(1);
    y_mm = dicom_coordinates(2);
    z_mm = dicom_coordinates(3);

    radius_mm = branch.Radius;
    density_mgml = branch.Density;
    
    
    is_final_node = isempty(branch.Children);
    PrintNodeToFile(fid, node_index, x_mm, y_mm, z_mm, radius_mm, density_mgml, is_final_node);
end

function PrintNodeToFile(fid, node_index, x_mm, y_mm, z_mm, radius_mm, density, is_final_node)
    if is_final_node
        is_final_node = 'y';
    else
        is_final_node = 'n';
    end
    output_string = sprintf('%u,%6.6g,%6.6g,%6.6g,%2.2g,%6.6g,%c\r\n', node_index, x_mm, y_mm, z_mm, radius_mm, density, is_final_node);
    fprintf(fid, regexprep(output_string, ' ', ''));
end
