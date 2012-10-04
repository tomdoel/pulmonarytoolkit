function TDWrite3DMetaFile(header_filename, image, resolution, data_type, offset)
    % TDWrite3DMetaFile. Writes out raw image data in metaheader & raw format
    %
    %     Syntax
    %     ------
    %
    %         TDWrite3DMetaFile(header_filename, image, resolution, data_type)
    %
    %             header_filename - full path to the header file
    %             image - 3D raw image to be saved
    %             resolution - voxel size in Matlab dimension order (y-x-z)
    %             data_type - uint8, char, short
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    [pathstr, name, ~] = fileparts(header_filename);
    raw_image_filename = fullfile(pathstr, [name, '.raw']);
    raw_image_filename_nopath = [name, '.raw'];
    
    fid = fopen(header_filename, 'w');
    if (fid <= 0)
        sprintf('Unable to open file %s\n', header_filename);
        error;
    end
    
    fprintf(fid, 'ObjectType = Image\n');
    fprintf(fid, 'NDims = 3\n');
    fprintf(fid, 'BinaryData = True\n');
    fprintf(fid, 'BinaryDataByteOrderMSB = False\n');
    fprintf(fid, 'TransformMatrix = 0 1 0 1 0 0 0 0 1\n');
    fprintf(fid, 'Offset = %s\n', offset);
    fprintf(fid, 'CenterOfRotation = 0 0 0\n');
    fprintf(fid, 'AnatomicalOrientation = RAI\n');
    fprintf(fid, 'ElementSpacing = %1.4f %1.4f %1.4f\n', resolution(1), resolution(2), resolution(3));
    fprintf(fid, 'DimSize = %d %d %d\n', size(image, 1), size(image, 2), size(image, 3));
    
    if (strcmp(data_type, 'char') || strcmp(data_type, 'uint8'))
        fprintf(fid, 'ElementType = MET_UCHAR\n');
    elseif(strcmp(data_type, 'short'))
        fprintf(fid, 'ElementType = MET_SHORT\n');
    end
    
    fprintf(fid, 'ElementDataFile = %s\n', raw_image_filename_nopath);
    
    fclose(fid);
    
    fid = fopen(raw_image_filename, 'w');
    if (fid <= 0)
        sprintf('Unable to open file %s\n', raw_image_filename);
    end
    fwrite(fid, image, data_type);
    fclose(fid);
end
    
