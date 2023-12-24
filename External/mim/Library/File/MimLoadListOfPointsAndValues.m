function [xc, yc, zc, value_list] = MimLoadListOfPointsAndValues(file_path, file_name, reporting)
    % Load a list of values and coordinates from a comma-separated text file
    %
    % Syntax:
    %     [xc, yc, zc, value_list] = MimLoadListOfPointsAndValues(file_path, file_name, reporting);
    %
    % Parameters:
    %     file_path: specify the location to save the DICOM data. One 2D file
    %     file_name: prefix for the filename.
    %     reporting (CoreReportingInterface): object for reporting progress and warnings
    %
    % Returns:
    %     xc: Data from column 1
    %     yc: Data from column 2
    %     zc: Data from column 3
    %     value_list: Data from column 4
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %     
    
    full_filename = fullfile(file_path, file_name);
    fid = fopen(full_filename);
    if fid < 0
        reporting.Error('MimLoadListOfPointsAndValues:FileNotFound', ['The file ' full_filename 'was not found or could not be read']);
    end
    data = textscan(fid, '%f%f%f%f', 'Delimiter', ',');
    fclose(fid);
    xc = data{1};
    yc = data{2};
    zc = data{3};
    value_list = data{4};
end
