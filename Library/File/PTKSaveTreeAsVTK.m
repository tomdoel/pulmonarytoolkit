function PTKSaveTreeAsVTK(tree_root, template_image, file_path, filename_prefix, reporting)
    % PTKSaveTreeAsVTK. Exports a tree structure into a VTK file
    %
    %     PTKSaveTreeAsVTK saves the tree whose root branch is tree_root into a
    %     .vtk file which can be viewed with ParaView. 
    %
    %     Syntax
    %     ------
    %
    %         PTKSaveTreeAsVTK(tree_root, file_path, base_filename, reporting)
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
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    % Get all branches in the tree
    linear_branch_list = tree_root.GetBranchesAsListUsingRecursion;
    num_branches = numel(linear_branch_list);
    num_points = num_branches + 1;
    
    % Set the index in each branch to be the index of its parent
    for branch_index = 1 : num_branches
        branch = linear_branch_list(branch_index);        
        branch.TemporaryIndex = 0;
    end
    for branch_index = 1 : num_branches
        branch = linear_branch_list(branch_index);
        for child = branch.Children
            child.TemporaryIndex = branch_index;
        end
    end
    
    point_coordinates = zeros(num_points, 3);
    
    % ToDo
    if isa(tree_root, 'PTKAirwayGrowingTree')
        point_coordinates(1, :) = [tree_root.StartCoords(2), tree_root.StartCoords(1), tree_root.StartCoords(3)];
    elseif isa(tree_root, 'PTKTreeModel')
        point = tree_root.StartPoint;
        dicom_coordinates = PTKImageCoordinateUtilities.PtkToCornerCoordinates([point.CoordI, point.CoordJ, point.CoordK], template_image);
        xc = dicom_coordinates(1);
        yc = dicom_coordinates(2);
        zc = dicom_coordinates(3);
        point_coordinates(1, :) = [xc, yc, zc];
    else
        point_coordinates(1, :) = [tree_root.StartPoint(2), tree_root.StartPoint(1), tree_root.StartPoint(3)];
    end
    lines = zeros(num_branches, 2);
    vertices = [0 : num_points - 1]';
    pressure = zeros(num_points, 1);
    flow_rate = zeros(num_points, 1);
    radius = zeros(num_points, 1);
    segment_index = zeros(num_points, 1);
    branches_to_write = zeros(num_points, 1);
    
    if ~isempty(tree_root.Radius)
        radius(1) = tree_root.Radius;
    end
    
    if isfield(tree_root, 'BranchProperties')
        if isfield(tree_root.BranchProperties, 'Flowrate')
            flow_rate(1) = branch.BranchProperties.Flowrate;
        end
        if isfield(tree_root.BranchProperties, 'Pressure')
            pressure(1) = branch.BranchProperties.Pressure;
        end
    end
    
    if isempty(tree_root.SegmentIndex);
        segment_index(1) = 0;
    else
        segment_index(1) = tree_root.SegmentIndex;
    end
    
    for branch_index = 1 : num_branches
        branch = linear_branch_list(branch_index);
        
        if isempty(branch.Parent)
            start_point_index = 0;
        else
            if (branch.TemporaryIndex == 0)
                reporting.Error('PTKSaveTreeAsVTK:CodeError', 'Parent index has not been set. Indicates a bug in the algorithm');
            end
            start_point_index = branch.TemporaryIndex;
        end
        end_point_index = branch_index;
        
        point_matlab_index = branch_index + 1;

        % Write the next point for this branch end point
        if isa(branch, 'PTKAirwayGrowingTree')
            point_coordinates(point_matlab_index, :) = [branch.EndCoords(2), branch.EndCoords(1), branch.EndCoords(3)];
        elseif isa(branch, 'PTKTreeModel')
            point = branch.EndPoint;
            dicom_coordinates = PTKImageCoordinateUtilities.PtkToCornerCoordinates([point.CoordI, point.CoordJ, point.CoordK], template_image);
            xc = dicom_coordinates(1);
            yc = dicom_coordinates(2);
            zc = dicom_coordinates(3);
            point_coordinates(point_matlab_index, :) = [xc, yc, zc];
        else
            point_coordinates(point_matlab_index, :) = [branch.EndPoint(2), branch.EndPoint(1), branch.EndPoint(3)];
        end
        
        
        lines(branch_index, :) = [start_point_index, end_point_index];
        
        % Write out parameters - NB. these correspond to points, not lines
        if ~isempty(branch.Radius)
            radius(point_matlab_index) = branch.Radius;
        end
        if isfield(branch, 'BranchProperties')
            if isfield(branch.BranchProperties, 'Flowrate')
                flow_rate(point_matlab_index) = branch.BranchProperties.Flowrate;
            end
            if isfield(branch.BranchProperties, 'Pressure')
                pressure(point_matlab_index) = branch.BranchProperties.Pressure;
            end
        end
        if isempty(branch.SegmentIndex);
            segment_index(point_matlab_index) = 0;
        else
            segment_index(point_matlab_index) = branch.SegmentIndex;
        end
        
    end
    
    vtk_file_name = fullfile(file_path, [filename_prefix '.vtk']);
    vtk_file_handle = fopen(vtk_file_name, 'w');
    
    
    WriteHeader(vtk_file_handle, reporting);
    
    WritePointCoordinates(vtk_file_handle, point_coordinates, reporting);
    WriteLines(vtk_file_handle, lines, reporting);
    WriteVertices(vtk_file_handle, vertices, reporting);    
    WritePointData(vtk_file_handle, pressure, flow_rate, radius, segment_index, branches_to_write, reporting);
    
    fclose(vtk_file_handle);
end

function WriteHeader(file_handle, reporting)
    WriteToFile(file_handle, '# vtk DataFile Version 3.0', reporting);
    WriteToFile(file_handle, 'vtk output', reporting);
    WriteToFile(file_handle, 'ASCII', reporting);
    WriteToFile(file_handle, 'DATASET POLYDATA', reporting);
    WriteToFile(file_handle, '', reporting);
end

function WriteToFile(file_handle, file_string, reporting)
    fprintf(file_handle, [file_string '\r\n']);
end

function WriteToFileWithoutNewLine(file_handle, file_string, reporting)
    fprintf(file_handle, file_string);
end

function points = WritePointCoordinates(file_handle, points, reporting)
    num_points = size(points, 1);
    first_line = sprintf('POINTS %u float', num_points);
    WriteToFile(file_handle, first_line);
    for point_index = 1 : num_points
        next_line = sprintf('%8.4f %8.4f %8.4f', points(point_index, 1), points(point_index, 2), points(point_index, 3));
        WriteToFile(file_handle, next_line);
    end
    WriteToFile(file_handle, '', reporting);
end

function WriteLines(file_handle, lines, reporting)
    num_lines = size(lines, 1);
    first_line = sprintf('LINES %u %u', num_lines, 3*num_lines);
    WriteToFile(file_handle, first_line, reporting);
    for line_index = 1 : num_lines
        next_line = sprintf('%u %u %u', 2, lines(line_index, 1), lines(line_index, 2));
        WriteToFile(file_handle, next_line);
    end
    WriteToFile(file_handle, '', reporting);
end

function WriteVertices(file_handle, vertices, reporting)
    num_vertices = size(vertices, 1);
    first_line = sprintf('VERTICES %u %u', num_vertices, 2*num_vertices);
    WriteToFile(file_handle, first_line, reporting);
    for line_index = 1 : num_vertices
        next_line = sprintf('%u %u', 1, vertices(line_index));
        WriteToFile(file_handle, next_line);
    end
    WriteToFile(file_handle, '', reporting);
end


function WritePointData(file_handle, pressure, flow_rate, radius, segment_index, branches, reporting)
    num_points = numel(pressure);
    first_line = sprintf('POINT_DATA %u', num_points);
    WriteToFile(file_handle, first_line, reporting);
    
    WriteDataValues(file_handle, pressure, 'Pressure', '%8.3f', reporting)
    WriteDataValues(file_handle, flow_rate, 'Flowrate', '%8.5f', reporting)
    WriteDataValues(file_handle, radius, 'Radius', '%10.8f', reporting)
    WriteDataValues(file_handle, branches, 'Branches', '%u', reporting)
    WriteDataValues(file_handle, segment_index, 'Segment', '%u', reporting)
end

function WriteDataValues(file_handle, data, name, format_string, reporting)
    WriteToFile(file_handle, ['SCALARS ' name ' float']);    
    WriteToFile(file_handle, 'LOOKUP_TABLE default');
    
    num_points = numel(data);
    
    col_index = 0;
    for line_index = 1 : num_points
        col_index = col_index + 1;
        next_line = sprintf([format_string ' '], data(line_index));
        if col_index > 5
            WriteToFile(file_handle, next_line);
            col_index = 0;
        else
            WriteToFileWithoutNewLine(file_handle, next_line);
        end
    end    
end
