function PTKWrite3DMetaFile(header_filename, image, resolution, data_type, offset, orientation, reporting)
    % PTKWrite3DMetaFile. Writes out raw image data in metaheader & raw format
    %
    %     Syntax
    %     ------
    %
    %         PTKWrite3DMetaFile(header_filename, image, resolution, data_type, offset, orientation, reporting)
    %
    %             header_filename - full path to the header file
    %             image - 3D raw image to be saved
    %             resolution - voxel size in Matlab dimension order (y-x-z)
    %             data_type - uint8, char, short
    %             offset
    %             orientation - of type PTKImageOrientation
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if nargin < 7
        reporting = PTKReportingDefault;
    end
    
    if nargin < 6 || isempty(orientation)
        orientation = PTKImageOrientation.Axial;
    end
    
    [pathstr, name, ~] = fileparts(header_filename);
    raw_image_filename = fullfile(pathstr, [name, '.raw']);
    raw_image_filename_nopath = [name, '.raw'];
    
    switch orientation
        case PTKImageOrientation.Axial            
            coordinates_save_order = [1, 2, 3];
            image_reorder = [1 2 3];
            image_flip = [false, false, true];
            anatomical_orientation = 'RAI';
            transform_matrix = '0 1 0 1 0 0 0 0 1';
            
        case PTKImageOrientation.Coronal
            coordinates_save_order = [3, 2, 1];
            image_reorder = [2, 3, 1];
            image_flip = [false, false, false];
            anatomical_orientation = 'RSA';
            transform_matrix = '1 0 0 0 0 -1 0 1 0';
            
        otherwise
            reporting.Error('PTKWrite3DMetaFile:UnsupportedOrientation', ['The save image orientation ' char(orientation) ' is now known or unsupported.']);
    end
    
    
    [fid, error_message] = fopen(header_filename, 'w');
    if (fid <= 0)
        reporting.Error('PTKWrite3DMetaFile:ErrorCreatingHeaderFile', ['Unable to create header file ' header_filename ' because of the following error: ' error_message]);
    end
    
    fprintf(fid, 'ObjectType = Image\n');
    fprintf(fid, 'NDims = 3\n');
    fprintf(fid, 'BinaryData = True\n');
    fprintf(fid, 'BinaryDataByteOrderMSB = False\n');
    fprintf(fid, ['TransformMatrix = ' transform_matrix '\n']);
    fprintf(fid, 'Offset = %1.4f %1.4f %1.4f\n', offset(coordinates_save_order(1)), offset(coordinates_save_order(2)), offset(coordinates_save_order(3)));
    fprintf(fid, 'CenterOfRotation = 0 0 0\n');
    fprintf(fid, ['AnatomicalOrientation = ' anatomical_orientation '\n']);
    fprintf(fid, 'ElementSpacing = %1.4f %1.4f %1.4f\n', resolution(coordinates_save_order(1)), resolution(coordinates_save_order(2)), resolution(coordinates_save_order(3)));
    fprintf(fid, 'DimSize = %d %d %d\n', size(image, coordinates_save_order(1)), size(image, coordinates_save_order(2)), size(image, coordinates_save_order(3)));
    
    if (strcmp(data_type, 'char') || strcmp(data_type, 'uint8'))
        fprintf(fid, 'ElementType = MET_UCHAR\n');
    elseif(strcmp(data_type, 'ushort'))
        fprintf(fid, 'ElementType = MET_USHORT\n');
    elseif(strcmp(data_type, 'short'))
        fprintf(fid, 'ElementType = MET_SHORT\n');
    end
    
    fprintf(fid, 'ElementDataFile = %s\n', raw_image_filename_nopath);
    
    fclose(fid);
    
    [fid, error_message] = fopen(raw_image_filename, 'w');
    if (fid <= 0)
        reporting.Error('PTKWrite3DMetaFile:ErrorCreatingRawFile', ['Unable to create raw data file ' raw_image_filename ' because of the following error: ' error_message]);        
    end
    
    if ~isequal(image_reorder, [1, 2, 3])
        image = permute(image, image_reorder);
    end
    
    for flip_dim = 1 : 3
        if image_flip(flip_dim)
            image = flipdim(image, flip_dim);
        end
    end
    
    fwrite(fid, image, data_type);
    fclose(fid);
end
    
