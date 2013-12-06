function PTKSaveTreeAsCMISS(tree_root, file_path, filename_prefix, coordinate_system, template_image, reporting)
    % PTKSaveTreeAsCMISS. Exports a tree structure into ipnode and ipelem files
    %
    %     Syntax
    %     ------
    %
    %         PTKSaveTreeAsCMISS(tree_root, file_path, base_filename, reporting)
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
        reporting.Error('PTKSaveTreeAsCMISS:BadArguments', 'No coordinate_system parameter specified');
    end
    
    if ~isa(coordinate_system, 'PTKCoordinateSystem')
        reporting.Error('PTKSaveTreeAsCMISS:BadArguments', 'coordinate_system parameter is not of type PTKCoordinateSystem');
    end
    
    
    ipnode_file_name = fullfile(file_path, [filename_prefix '.ipnode']);
    ipelem_file_name = fullfile(file_path, [filename_prefix '.ipelem']);
    exnode_file_name = fullfile(file_path, [filename_prefix '.exnode']);
    exelem_file_name = fullfile(file_path, [filename_prefix '.exelem']);
    
    linear_branch_list = tree_root.GetBranchesAsList;
    
    num_branches = length(linear_branch_list);
    
    num_nodes = num_branches + 1;
    num_elements = num_branches;

    % Create the node file (contains the coordinates and radius)
    ipnode_file_handle = fopen(ipnode_file_name, 'w');
    if ipnode_file_handle == -1
        reporting.Error('PTKSaveTreeAsCMISS:CreateFileFailed', ['I could not create the file ' ipnode_file_name '. Please check the disk permissions to ensure I have write access.']);
    end
    
    exnode_file_handle = fopen(exnode_file_name, 'w');
    if exnode_file_handle == -1
        fclose(ipnode_file_handle);
        reporting.Error('PTKSaveTreeAsCMISS:CreateFileFailed', ['I could not create the file ' exnode_file_name '. Please check the disk permissions to ensure I have write access.']);
    end
    
    ipelem_file_handle = fopen(ipelem_file_name, 'w');
    if ipelem_file_handle == -1
        fclose(ipnode_file_handle);
        fclose(exnode_file_handle);
        reporting.Error('PTKSaveTreeAsCMISS:CreateFileFailed', ['I could not create the file ' ipelem_file_name '. Please check the disk permissions to ensure I have write access.']);
    end
    
    exelem_file_handle = fopen(exelem_file_name, 'w');
    if exelem_file_handle == -1
        fclose(ipnode_file_handle);
        fclose(exnode_file_handle);
        fclose(ipelem_file_handle);
        reporting.Error('PTKSaveTreeAsCMISS:CreateFileFailed', ['I could not create the file ' exelem_file_name '. Please check the disk permissions to ensure I have write access.']);
    end
    
    % Write header of ipnode file
    WriteIpnodeHeader(ipnode_file_handle, num_nodes);
    
    % Write header of exnode file
    WriteExnodeHeader(exnode_file_handle, num_nodes);
    
    % Write header of ipelem file
    WriteIpelemHeader(ipelem_file_handle, num_elements);
    
    % Write header of ipelem file
    WriteExelemHeader(exelem_file_handle, num_elements);

    % In converting the tree structure to nodes and elements, we create one node
    % at the start of the tree, and then a node at the end of each branch. 
    % Each element represents a branch and connects two of these nodes.

    previous_values = [0, 0, 0];

    % First create the node at the start of the tree
    first_point = tree_root.StartPoint;
    
    first_point_converted = PTKImageCoordinateUtilities.ConvertFromPTKCoordinates([first_point.CoordX, first_point.CoordY, first_point.CoordZ], coordinate_system, template_image);

    start_x_mm = first_point_converted(1);
    start_y_mm = first_point_converted(2);
    start_z_mm = first_point_converted(3);
    start_radius_mm = tree_root.Radius;
    start_density_mgml = tree_root.Density;
    current_node_index = 1;
    
    % Print out the first node (top of the tree) to the files
    previous_values = PrintIpnodeToFile(ipnode_file_handle, current_node_index, start_x_mm, start_y_mm, start_z_mm, previous_values);
    PrintExnodeToFile(exnode_file_handle, current_node_index, start_x_mm, start_y_mm, start_z_mm, start_radius_mm, start_density_mgml);
    
    % The TemporaryIndex property in each branch is used to store the node index
    % of the node which was created at the end of the parent branch.
    % For the first branch we set this to the 1, the index of the node we have
    % just created at the top of the airways.
    linear_branch_list(1).TemporaryIndex = current_node_index;
    
    % The next node index will be 2. Nodes are created at the endpoints of each
    % branch, so the node from the endpoint of the first branch will have index
    % 2, because node index 1 is the tree start point we have created above.
    current_node_index = current_node_index + 1;

    % Now go through the rest of the tree, add a new node at the end of each
    % branch, and add an element connecting this new node to its parent node
    % (the endpoint of the parent branch)
    for branch = linear_branch_list
        
        reporting.UpdateProgressValue(round(100*current_node_index/num_branches));
        parent_node_index = branch.TemporaryIndex;
        
        % Write branch to node file (the end point will be the node coordinate).
        previous_values = PrintBranchToFileAsNode(ipnode_file_handle, exnode_file_handle, current_node_index, branch, previous_values, coordinate_system, template_image);
        
        % Write to the element file for each branch 
        PrintIpelemToFile(ipelem_file_handle, parent_node_index, current_node_index)
        PrintExelemToFile(exelem_file_handle, parent_node_index, current_node_index)
        
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
    fclose(ipnode_file_handle);
    fclose(ipelem_file_handle);
    fclose(exnode_file_handle);    
    fclose(exelem_file_handle);
end
   
function WriteIpelemHeader(file_handle, num_elements)
    fprintf(file_handle, ' CMISS Version 2.1  ipelem File Version 2\r\n');
    fprintf(file_handle, ' Heading: Data to nodes\r\n');
    fprintf(file_handle, ' \r\n');
    fprintf(file_handle, ' The number of elements is [1]: %5u\r\n', num_elements);
    fprintf(file_handle, ' \r\n');    
end

function WriteIpnodeHeader(file_handle, num_nodes)
    fprintf(file_handle, ' CMISS Version 2.1  ipnode File Version 2\r\n');
    fprintf(file_handle, ' Heading: Data to nodes\r\n');
    fprintf(file_handle, ' \r\n');
    fprintf(file_handle, ' The number of nodes is [%6u]: %6u\r\n', num_nodes, num_nodes);
    fprintf(file_handle, ' Number of coordinates [3]: 3\r\n');
    fprintf(file_handle, ' Do you want prompting for different versions of nj=1 [N]? N\r\n');
    fprintf(file_handle, ' Do you want prompting for different versions of nj=2 [N]? N\r\n');
    fprintf(file_handle, ' Do you want prompting for different versions of nj=3 [N]? N\r\n');
    fprintf(file_handle, ' The number of derivatives for coordinate 1 is [0]: 0\r\n');
    fprintf(file_handle, ' The number of derivatives for coordinate 2 is [0]: 0\r\n');
    fprintf(file_handle, ' The number of derivatives for coordinate 3 is [0]: 0\r\n');
    fprintf(file_handle, ' \r\n');    
end

function WriteExnodeHeader(file_handle, num_nodes)
    fprintf(file_handle, ' Group name: central_airway \r\n');
    fprintf(file_handle, ' #Fields=           3\r\n');
    fprintf(file_handle, ' 1) coordinates, coordinate, rectangular cartesian, #Components=3\r\n');
    fprintf(file_handle, '   x.  Value index= 1, #Derivatives=0\r\n');
    fprintf(file_handle, '   y.  Value index= 2, #Derivatives=0\r\n');
    fprintf(file_handle, '   z.  Value index= 3, #Derivatives=0\r\n');
    fprintf(file_handle, ' 2) radius, field, rectangular cartesian, #Components=1\r\n');
    fprintf(file_handle, '  radius.  Value index= 4, #Derivatives=0\r\n');
    fprintf(file_handle, ' 3) density, field, rectangular cartesian, #Components=1\r\n');
    fprintf(file_handle, '  density.  Value index= 5, #Derivatives=0\r\n');
end

function WriteExelemHeader(file_handle, num_elements)
    fprintf(file_handle, ' Group name: central_airway \r\n');
    fprintf(file_handle, ' Shape.  Dimension=1\r\n');
    fprintf(file_handle, ' #Scale factor sets= 1\r\n');
    fprintf(file_handle, '   l.Lagrange, #Scale factors= 2\r\n');
    fprintf(file_handle, ' #Nodes= 2\r\n');
    fprintf(file_handle, '#Fields=3\r\n');
    fprintf(file_handle, ' 1) coordinates, coordinate, rectangular cartesian, #Components=3\r\n');
    fprintf(file_handle, '   x.  l.Lagrange, no modify, standard node based.\r\n');
    fprintf(file_handle, '     #Nodes= 2\r\n');
    fprintf(file_handle, '      1.  #Values=1\r\n');
    fprintf(file_handle, '       Value indices:     1\r\n');
    fprintf(file_handle, '       Scale factor indices:   1\r\n');
    fprintf(file_handle, '      2.  #Values=1\r\n');
    fprintf(file_handle, '       Value indices:     1\r\n');
    fprintf(file_handle, '       Scale factor indices:   2\r\n');
    fprintf(file_handle, '   y.  l.Lagrange, no modify, standard node based.\r\n');
    fprintf(file_handle, '     #Nodes= 2\r\n');
    fprintf(file_handle, '      1.  #Values=1\r\n');
    fprintf(file_handle, '       Value indices:     1\r\n');
    fprintf(file_handle, '       Scale factor indices:   1\r\n');
    fprintf(file_handle, '      2.  #Values=1\r\n');
    fprintf(file_handle, '       Value indices:     1\r\n');
    fprintf(file_handle, '       Scale factor indices:   2\r\n');
    fprintf(file_handle, '   z.  l.Lagrange, no modify, standard node based.\r\n');
    fprintf(file_handle, '     #Nodes= 2\r\n');
    fprintf(file_handle, '      1.  #Values=1\r\n');
    fprintf(file_handle, '       Value indices:     1\r\n');
    fprintf(file_handle, '       Scale factor indices:   1\r\n');
    fprintf(file_handle, '      2.  #Values=1\r\n');
    fprintf(file_handle, '       Value indices:     1\r\n');
    fprintf(file_handle, '       Scale factor indices:   2\r\n');
    fprintf(file_handle, ' 2) radius, field, rectangular cartesian, #Components=1\r\n');
    fprintf(file_handle, '   radius.  l.Lagrange, no modify, standard node based.\r\n');
    fprintf(file_handle, '     #Nodes= 2\r\n');
    fprintf(file_handle, '      1.  #Values=1\r\n');
    fprintf(file_handle, '       Value indices:     1\r\n');
    fprintf(file_handle, '       Scale factor indices:   1\r\n');
    fprintf(file_handle, '      2.  #Values=1\r\n');
    fprintf(file_handle, '       Value indices:     1\r\n');
    fprintf(file_handle, '       Scale factor indices:   2\r\n');
    fprintf(file_handle, ' 3) density, field, rectangular cartesian, #Components=1\r\n');
    fprintf(file_handle, '   density.  l.Lagrange, no modify, standard node based.\r\n');
    fprintf(file_handle, '     #Nodes= 2\r\n');
    fprintf(file_handle, '      1.  #Values=1\r\n');
    fprintf(file_handle, '       Value indices:     1\r\n');
    fprintf(file_handle, '       Scale factor indices:   1\r\n');
    fprintf(file_handle, '      2.  #Values=1\r\n');
    fprintf(file_handle, '       Value indices:     1\r\n');
    fprintf(file_handle, '       Scale factor indices:   2\r\n');
end

function PrintIpelemToFile(element_file_handle, parent_index, child_index)
    fprintf(element_file_handle, ' Element number [%5u]: %5u\r\n', child_index - 1, child_index - 1);
    fprintf(element_file_handle, ' The number of geometric Xj-coordinates is [3]: 3\r\n');
    fprintf(element_file_handle, ' The basis function type for geometric variable 1 is [1]:  1\r\n');
    fprintf(element_file_handle, ' The basis function type for geometric variable 2 is [1]:  1\r\n');
    fprintf(element_file_handle, ' The basis function type for geometric variable 3 is [1]:  1\r\n');
    fprintf(element_file_handle, ' Enter the 2 global numbers for basis 1: %5u %5u\r\n', parent_index, child_index);
    fprintf(element_file_handle, ' \r\n');
end

function PrintExelemToFile(file_handle, parent_index, child_index)
    fprintf(file_handle, 'Element: %6u 0 0\r\n', child_index - 1);
    fprintf(file_handle, '   Nodes:\r\n');
    fprintf(file_handle, '     %6u %6u\r\n', parent_index, child_index);
    fprintf(file_handle, '   Scale factors:\r\n');
    fprintf(file_handle, '       0.1000000000000000E+01   0.1000000000000000E+01\r\n');
end

function previous_values = PrintBranchToFileAsNode(ipnode_file_handle, exnode_file_handle, node_index, branch, previous_values, coordinate_system, template_image)

    % We define nodes using the end coordinate of each branch, since this is the
    % bifurcation point
    last_point = branch.EndPoint;
    
    converted_coordinates = PTKImageCoordinateUtilities.ConvertFromPTKCoordinates([last_point.CoordX, last_point.CoordY, last_point.CoordZ], coordinate_system, template_image);
    
    x_mm = converted_coordinates(1);
    y_mm = converted_coordinates(2);
    z_mm = converted_coordinates(3);
    radius_mm = branch.Radius;
    density_mgml = branch.Density;
    
    previous_values = PrintIpnodeToFile(ipnode_file_handle, node_index, x_mm, y_mm, z_mm, previous_values);
    PrintExnodeToFile(exnode_file_handle, node_index, x_mm, y_mm, z_mm, radius_mm, density_mgml);
end

function previous_coordinates = PrintIpnodeToFile(node_file_handle, node_index, x_mm, y_mm, z_mm, previous_coordinates)
    fprintf(node_file_handle, ' Node number [%6u]: %6u\r\n', node_index, node_index);
    fprintf(node_file_handle, ' The Xj(1) coordinate is [%12.5E]:   %#19.17G\r\n', previous_coordinates(1), x_mm);
    fprintf(node_file_handle, ' The Xj(2) coordinate is [%12.5E]:   %#19.17G\r\n', previous_coordinates(2), y_mm);
    fprintf(node_file_handle, ' The Xj(3) coordinate is [%12.5E]:   %#19.17G\r\n', previous_coordinates(3), z_mm);
    fprintf(node_file_handle, ' \r\n');
    
    previous_coordinates = [x_mm, y_mm, z_mm];
end

function PrintExnodeToFile(file_handle, node_index, x_mm, y_mm, z_mm, radius_mm, density_mgml)
    fprintf(file_handle, '  Node: %5u\r\n', node_index);
    fprintf(file_handle, '   %19.17G   %19.17G   %19.17G   %19.17G   %19.17G\r\n', x_mm, y_mm, z_mm, radius_mm, density_mgml);
end

