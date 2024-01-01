function root_branch = PTKLoadTreeFromChaste(file_path, node_filename, edge_filename, coordinate_system, template_image, reporting)
    % Load a tree strucure from branches stored in Chaste format node/element files
    %
    % Syntax:
    %     root_branch = PTKLoadTreeFromChaste(file_path, filename_prefix, reporting);
    %
    % Parameters:
    %     root_branch: root branch in a PTKTreeModel structure 
    %     file_path: path where the node and edge files are to be stored
    %     node_filename: name of the node file
    %     edge_filename: name of the edge file
    %     coordinate_system: 
    %     template_image: used tp provide a reference coordinate system
    %     reporting (Optional[CoreReportingInterface])) - an object 
    %         for reporting progress and warnings
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    if nargin < 4
        error('PTKLoadTreeFromChaste:BadArguments', 'No coordinate_system parameter specified');
    end
    
    if nargin < 6
        reporting = CoreReportingDefault();
    end    
    
    if ~isa(coordinate_system, 'MimCoordinateSystem')
        reporting.Error('PTKLoadTreeFromChaste:BadArguments', 'coordinate_system parameter is not of type MimCoordinateSystem');
    end
    
    if ~CoreDiskUtilities.FileExists(file_path, node_filename)
        reporting.Error('PTKLoadTreeFromChaste:FileDoesNotExist', ['The node file ', node_filename ,' does not exist']);
    end
    
    if ~CoreDiskUtilities.FileExists(file_path, edge_filename)
        reporting.Error('PTKLoadTreeFromChaste:FileDoesNotExist', ['The edge file ', edge_filename ,' does not exist']);
    end
    
    [node_index, x, y, z, radius, is_terminal, node_index_1, node_index_2] = PTKLoadNodeListFromChaste(file_path, node_filename, edge_filename, reporting);
    
    ptk_coordinates = MimImageCoordinateUtilities.ConvertToPTKCoordinates([x, y, z], coordinate_system, template_image);
    x = ptk_coordinates(:, 1);
    y = ptk_coordinates(:, 2);
    z = ptk_coordinates(:, 3);
    
    root_branch = PTKCreateTreeFromNodesAndElements(node_index, x, y, z, radius, node_index_1, node_index_2, reporting);
end
