function start_nodes = PTKConvertListsToNodes(node_index_list, ic, jc, kc, radius_list, node_index_1, node_index_2, reporting)
    % PTKConvertListsToNodes. Converts a list of point indices, coordinates and parameters into a node structure
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       

    valid_node_indices = [];
    
    % Load in all the node points into an array
    nodes = PTKNode.empty;
    for index = 1 : length(ic)
        next_node = PTKNode;
        next_node.CentrelinePoint = PTKCentrelinePoint(ic(index), jc(index), kc(index), radius_list(index), []);
        node_number = node_index_list(index);
        nodes(node_number + 1) = next_node;
        valid_node_indices(end + 1) = node_number;
    end
    
    % Use the element lists to set up parent-child relationships
    for element_index = 1 : length(node_index_1)
        node_a_index = node_index_1(element_index);
        node_b_index = node_index_2(element_index);
        if (node_a_index ~= node_b_index)
            parent_branch = nodes(node_a_index + 1);
            child_branch = nodes(node_b_index + 1);
            child_branch.Parent = parent_branch;
            parent_branch.Children = [parent_branch.Children, child_branch];
        end
    end
    
    % Find the starting nodes (those with no parents)
    start_nodes = [];
    for index = 1 : length(valid_node_indices)
        node = nodes(valid_node_indices(index) + 1);
        if isempty(node.Parent)
            start_nodes = [start_nodes, node];
        end
    end
end