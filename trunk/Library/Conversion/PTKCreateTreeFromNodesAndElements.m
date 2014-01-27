function root_branch = PTKCreateTreeFromNodesAndElements(node_index_list, xc, yc, zc, radius_list, node_index_1, node_index_2, reporting)
    % PTKCreateTreeFromNodesAndElements. Converts a list of nodes into a PTKModelTree
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    start_nodes = PTKConvertListsToNodes(node_index_list, xc, yc, zc, radius_list, node_index_1, node_index_2, reporting);

    if numel(start_nodes) ~= 1
        reporting.Error('PTKCreateTreeFromNodesAndElements:MoreThanOneStartNode', 'More than one parent node was found in this file');
    end
    
    % Create the root branch
    root_branch = PTKTreeModel;
    branches_to_do = PTKPair(root_branch, start_nodes(1));
    
    % We need to keep branches together with their node; easy to do this with a
    % PTKPair
    while ~isempty(branches_to_do)
        next_branch_pair = branches_to_do(end);
        branches_to_do(end) = [];
        current_branch = next_branch_pair.First;
        
        next_node = next_branch_pair.Second;
        
        % Build up the centreline until we reach a bifurcation, or the end of
        % the tree
        centreline = next_node.CentrelinePoint;
        node_file_index = centreline.Parameters.NodeFileIndex;
        while numel(next_node.Children) == 1
            next_node = next_node.Children;
            centreline(end + 1) = next_node.CentrelinePoint;
        end
        
        current_branch.Centreline = centreline;
        current_branch.StartPoint = centreline(1);
        current_branch.EndPoint = centreline(end);
        current_branch.TemporaryIndex = node_file_index;
        
        % At a bifurcation, create a new branch for each child
        for child_node = next_node.Children
            branches_to_do(end + 1) = PTKPair(PTKTreeModel(current_branch), child_node);
        end        
    end
end