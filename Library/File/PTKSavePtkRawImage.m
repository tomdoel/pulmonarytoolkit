function PTKSavePtkRawImage(raw_image, file_path, raw_filename, compression, reporting)
    % PTKSavePtkRawImage. Saves raw image data from disk
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    full_raw_filename = fullfile(file_path, raw_filename);
    
    if isempty(compression)
        SaveUncompressed(full_raw_filename, raw_image, reporting);
    elseif strcmp(compression, 'png')
        SaveCompressed(full_raw_filename, raw_image, 'png', [], [], reporting);
    elseif strcmp(compression, 'deflate')
        SaveCompressed(full_raw_filename, raw_image, 'tiff', 'Compression', 'deflate', reporting);
    else
        reporting.Error('PTKSavePtkRawImage:UnknownCompression', 'Unknown compression format');
    end
end

function SaveCompressed(full_raw_filename, raw_image, format, param1, param2, reporting)
    image_class = class(raw_image);

    if ~PTKDiskUtilities.CompressionSupported(format, image_class, reporting)
        reporting.LogVerbose([format, ' compression not supported for image data type ', image_class]);
        disp([format, ' compression not supported for image data type ', image_class]);
        SaveUncompressed(full_raw_filename, raw_image);
        return;
    end
    
    image_data_size_3d = size(raw_image);
    image_data_size_2d = [image_data_size_3d(1)*image_data_size_3d(2), image_data_size_3d(3)];
    output_size = image_data_size_2d;
    switch image_class
        case 'int8'
            output_class = 'uint8';
        case 'int16'
            output_class = 'uint16';
        case 'int32'
            output_class = 'uint32';
        case 'int64'
            output_class = 'uint64';
        case 'single'
            output_class = 'uint16';
            output_size(2) = 2*output_size(2);
        case 'double'
            output_class = 'uint16';
            output_size(2) = 2*output_size(2);
        otherwise
            output_class = image_class;
    end
    
    raw_image = reshape(raw_image, image_data_size_2d);
    
    if strcmp(output_class, image_class)
        raw_image_write = raw_image;
    else
        raw_image_write = zeros(output_size, output_class);
        raw_image_write(:) = typecast(raw_image(:), output_class);
    end
    
    if isempty(param1)
        imwrite(raw_image_write, full_raw_filename, format);
    else
        imwrite(raw_image_write, full_raw_filename, format, param1, param2);
    end
end

function SaveUncompressed(full_raw_filename, raw_image, reporting)
    data_type = class(raw_image);
    
    % Logical data will be saved in bitwise format
    if strcmp(data_type, 'logical')
        file_data_type = 'ubit1';
    else
        file_data_type = data_type;
    end
    
    % Save raw image data
    fid = fopen(full_raw_filename, 'wb');
    fwrite(fid, raw_image, file_data_type);
    fclose(fid);
    
end

