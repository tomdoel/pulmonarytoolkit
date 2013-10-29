function [xc, yc, zc, value_list] = PTKLoadListOfPointsAndValues(file_path, file_name, reporting)
    % PTKLoadListOfPointsAndValues. Load a list of values and coordinates from a
    %     comma-separated text file
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
    
    full_filename = fullfile(file_path, file_name);
    fid = fopen(full_filename);
    if fid < 0
        reporting.Error('PTKLoadListOfPointsAndValues:FileNotFound', ['The file ' full_filename 'was not found or could not be read']);
    end
    data = textscan(fid, '%f%f%f%f', 'Delimiter', ',');
    fclose(fid);
    xc = data{1};
    yc = data{2};
    zc = data{3};
    value_list = data{4};
end