function PTKSaveListOfPointsAndValues(file_path, file_name, xc, yc, zc, value_list, coordinate_system, template_image)
    % PTKSaveListOfPointsAndValues. Exports a list of coordinates and values
    %
    %     Syntax
    %     ------
    %
    %         PTKSaveListOfPointsAndValues(file_path, file_name, xc, yc, zc, value_list, template_image, reporting)
    %
    %             file_path       is the path where the output file is to be 
    %                             stored
    %             file_name       is the file name
    %             xc, yc, zx      are the coordinates in PTK cordinates
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
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    if nargin < 7
        reporting.Error('PTKSaveListOfPointsAndValues:BadArguments', 'No coordinate_system parameter specified');
    end
    
    if ~isa(coordinate_system, 'PTKCoordinateSystem')
        reporting.Error('PTKSaveListOfPointsAndValues:BadArguments', 'coordinate_system parameter is not of type PTKCoordinateSystem');
    end

    PTKDiskUtilities.CreateDirectoryIfNecessary(file_path);
    results_file_name = fullfile(file_path, file_name);
    file_handle = fopen(results_file_name, 'w');
    
    number_points = length(xc);
    
    for index = 1 : number_points
        dicom_coords = PTKImageCoordinateUtilities.ConvertFromPTKCoordinates([xc(index), yc(index), zc(index)], coordinate_system, template_image);
        coord_x = dicom_coords(1);
        coord_y = dicom_coords(2);
        coord_z = dicom_coords(3);
        
        density = value_list(index);
        if any(density(:) == 0)
            disp('Warning: zero density');
        end
        
        output_string = sprintf('%6.6g,%6.6g,%6.6g,%6.6g\r\n', coord_x, coord_y, coord_z, density);
        fprintf(file_handle, regexprep(output_string, ' ', ''));
    end
    
    fclose(file_handle);
end
