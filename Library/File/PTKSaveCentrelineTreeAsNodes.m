function PTKSaveCentrelineTreeAsNodes(tree_root, file_path, filename_prefix, reporting)
    % PTKSaveCentrelineTreeAsNodes. Exports a centreline tree structure into node and element files
    %
    %     Syntax
    %     ------
    %
    %         PTKSaveCentrelineTreeAsNodes(tree_root, file_path, base_filename, reporting)
    %
    %             tree_root       is the root branch in a PTKTreeModel structure 
    %             file_path       is the path where the node and element files
    %                             are to be stored
    %             filename_prefix is the filename prefix. The node and element
    %                             files will have '_node.txt' and '_element.txt'
    %                             appended to this prefix before saving.
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

    node_file_name = fullfile(file_path, [filename_prefix '_node.txt']);
    element_file_name = fullfile(file_path, [filename_prefix '_element.txt']);
    
    num_nodes = tree_root.CountPointsInTree;
    linear_branch_list = tree_root.GetBranchesAsListUsingRecursion;

    % Create the node file (contains the coordinates and radius)
    node_file_handle = fopen(node_file_name, 'w');
    element_file_handle = fopen(element_file_name, 'w');
    
    % The first file entry is the number of nodes
    fprintf(node_file_handle, '%u\r\n', num_nodes);
    fprintf(element_file_handle, '%u\r\n', num_nodes);
    
    % Set the root node as having parent node 0 (itself)
    linear_branch_list(1).TemporaryIndex = 0;
    current_node_index = 0;
    
    for branch = linear_branch_list
        parent_node_index = branch.TemporaryIndex;
        points = branch.Centreline;
        for point_index = 1 : length(points)
            point = points(point_index);
            is_endpoint = (point_index == length(points)) && isempty(branch.Children);
            
            % Write point to node file
            PrintNodeToFile(node_file_handle, current_node_index, point, is_endpoint);
            
            % Write (parent, current_node_index) to element file
            PrintElementToFile(element_file_handle, parent_node_index, current_node_index)
            
            parent_node_index = current_node_index;
            current_node_index = current_node_index + 1;
        end
        
        % Set the parent for the first point in each child branch to be the last
        % point in the current branch
        if ~isempty(branch.Children)
            for child = branch.Children
                child.TemporaryIndex = parent_node_index;
            end
        end
    end
    
%     % The element file ends with (0,0) without terminating newline
%     fprintf(element_file_handle, '%u,%u', 0, 0);
    
    % Close the files
    fclose(node_file_handle);
    fclose(element_file_handle);

    
    
    
    
    

    
end


function PrintElementToFile(fid, parent_index, child_index)
    fprintf(fid, '%u,%u\r\n', parent_index, child_index);
end

function PrintNodeToFile(fid, node_index, point, is_endpoint)
    xc = point.CoordJ;
    yc = point.CoordI;
    zc = point.CoordK;
    radius = point.Radius;
    if is_endpoint
        is_final_node = 'y';
    else
        is_final_node = 'n';
    end
    
    output_string = sprintf('%u,%6.6g,%6.6g,%6.6g,%2.2g,%c\r\n', node_index, xc, yc, zc, radius, is_final_node);
    fprintf(fid, regexprep(output_string, ' ', ''));
%     fprintf(fid, '%u,%3.3f,%3.3f,%3.3f,%3.1f,%c\r\n', node_index, xc, yc, zc, radius, is_final_node);
    
end