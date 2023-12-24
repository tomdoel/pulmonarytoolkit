function raw_image = CoreLoadRawImage(file_path, raw_filename, data_type, image_size, compression, reporting)
    % Load raw image data from disk
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    full_raw_filename = fullfile(file_path, raw_filename);
    if ~exist(full_raw_filename, 'file');
        throw(MException(MimErrors.RawFileNotFoundErrorId, ['The raw file ' raw_filename ' does not exist']));
    end
    
    if isempty(compression)
        raw_image = LoadUncompressed(full_raw_filename, data_type, image_size, reporting);
    elseif strcmp(compression, 'png')
        raw_image = LoadCompressed(full_raw_filename, data_type, image_size, 'png', reporting);
    elseif strcmp(compression, 'deflate')
        raw_image = LoadCompressed(full_raw_filename, data_type, image_size, 'tiff', reporting);
    else
        reporting.Error('CoreLoadRawImage:UnknownCompression', 'Unknown compression format');
    end
end

function raw_image = LoadCompressed(full_raw_filename, data_type, image_size, format, reporting)
    
    if ~MimDiskUtilities.CompressionSupported(format, data_type, reporting)
        reporting.LogVerbose([format, ' compression not supported for image data type ', data_type]);
        disp([format, ' compression not supported for image data type ', data_type]);
        raw_image = LoadUncompressed(full_raw_filename, data_type, image_size);
        return;
    end
    
    raw_image = imread(full_raw_filename, format);
    
    if strcmp(data_type, class(raw_image))
        raw_image = reshape(raw_image, image_size);
    else
        raw_image = reshape(typecast(raw_image(:), data_type), image_size);
    end
end

function raw_image = LoadUncompressed(full_raw_filename, data_type, image_size, reporting)

    if strcmp(data_type, 'logical')
        raw_image = false(image_size);
    else
        raw_image = zeros(image_size, data_type);
    end
    
    % Logical data is saved in bitwise format
    if strcmp(data_type, 'logical')
        file_data_type = 'ubit1';
    else
        file_data_type = data_type;
    end
    
    fid = fopen(full_raw_filename, 'rb');
    data = fread(fid, ['*' file_data_type]);
    if isempty(data)
        raw_image = [];
    else
        if numel(data) == prod(image_size)
            raw_image(:) = data(:);
        else
            raw_image(:) = data(1:numel(raw_image));
        end
    end
    fclose(fid);
end

