function root_branch = PTKLoadCentrelineTreeFromNodes(file_path, filename_prefix, coordinate_system, template_image, reporting)
    % PTKLoadCentrelineTreeFromNodes. Load a tree strucure from centreline points stored in node/element files
    %
    %     Syntax
    %     ------
    %
    %         root_branch = PTKLoadCentrelineTreeFromNodes(file_path, filename_prefix, reporting)
    %
    %             root_branch     is the root branch in a PTKTreeModel structure 
    %             file_path       is the path where the node and element files
    %                             are to be stored
    %             filename_prefix is the filename prefix. The node and element
    %                             files will have '_node.txt' and '_element.txt'
    %                             appended to this prefix before saving.
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
    
    if nargin < 3
        reporting.Error('PTKLoadCentrelineTreeFromNodes:BadArguments', 'No coordinate_system parameter specified');
    end
    
    if ~isa(coordinate_system, 'PTKCoordinateSystem')
        reporting.Error('PTKLoadCentrelineTreeFromNodes:BadArguments', 'coordinate_system parameter is not of type PTKCoordinateSystem');
    end

    node_file = [filename_prefix '_node.txt'];
    node_file = fullfile(file_path, node_file);
    element_file = [filename_prefix '_element.txt'];
    element_file = fullfile(file_path, element_file);
    
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
    num_nodes = textscan(fid, '%u', 1);
    num_nodes = num_nodes{1};
    
    % Subsequent lines are node_Number, x, y, z, radius, final_node?(y or n)
    element_data = textscan(fid, '%u%u', num_nodes, 'Delimiter', ',');
    fclose(fid);
    
    node_points = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    
    % Create a new point for each node
    for node_index = 1 : num_nodes
        node_number = node_data{1}(node_index);
        xc = node_data{2}(node_index);
        yc = node_data{3}(node_index);
        zc = node_data{4}(node_index);
        radius = node_data{5}(node_index);
        is_end_node = node_data{6}(node_index);

        point_parameters = [];
        point_parameters.Radius = radius;
        
        new_coords = PTKImageCoordinateUtilities.ConvertToPTKCoordinates([xc, yc, zc], coordinate_system, template_image);
        new_point = PTKCentrelinePoint(new_coords(1), new_coords(2), new_coords(3), point_parameters);
        node_points(node_number + 1) = new_point;
    end
    
    % Determine number of child points at each point - we will use this to
    % find bifurcation points
    number_of_child_points = zeros(num_nodes, 1);
    for element_index = 1 : length(element_data{1})
        parent_index = element_data{1}(element_index) + 1;
        child_index = element_data{2}(element_index) + 1;
        if parent_index ~= child_index
            number_of_child_points(parent_index) = number_of_child_points(parent_index) + 1;
        end
    end
    
    % Allocate branches to each point
    branch_for_point = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    first_branch = PTKTreeModel;
    first_branch.Centreline(end + 1) = node_points(1);
    branch_for_point(1) = first_branch;
    number_of_elements = length(element_data{1});

    for element_index = 1 : number_of_elements
        parent_index = element_data{1}(element_index) + 1;
        child_index = element_data{2}(element_index) + 1;
        
        if parent_index ~= child_index
            parent_branch =  branch_for_point(parent_index);
            if isempty(parent_branch)
                error('empty parent');
            end
            
            % If this is a branchpoint (the parent has more than one child) then
            % we create a new branch for the child
            if (parent_index ~= child_index) && (number_of_child_points(parent_index) > 1)
                this_branch = PTKTreeModel;
                this_branch.SetParent(parent_branch);
            else
                % Otherwise the child gets the same branch as the parent
                this_branch = parent_branch;
            end
            
            % Either way, we add the corresponding point to the end of the
            % centreline
            branch_for_point(child_index) = this_branch;
            this_branch.Centreline(end + 1) = node_points(child_index);
        end
    end
    
    
    root_branch = branch_for_point(1);
    
    % Remove the terminating nodes (which are not branches);
%     root_branch.RemoveTerminatingNodes;
    
end

