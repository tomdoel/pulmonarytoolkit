function [xc, yc, zc, value_list] = MimLoadListOfPointsAndValues(file_path, file_name, reporting)
    % CoreLoadListOfPointsAndValues. Load a list of values and coordinates from a
    %     comma-separated text file
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
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