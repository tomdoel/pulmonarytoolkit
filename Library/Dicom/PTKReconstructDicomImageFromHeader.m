function image_data = PTKReconstructDicomImageFromHeader(header, is_little_endian, reporting)
    % PTKReconstructDicomImageFromHeader. Converts Dicom pixel data into an image
    %
    % Usage:
    %     image_data = PTKReconstructDicomImageFromHeader(header, is_little_endian, reporting)
    %
    %     header - A structure holding the Dicom tags needed for image
    %         reconstruction
    %
    %     is_little_endian - true if the pixel data is little endian
    %
    %     reporting - a PTKReporting object for error reporting
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if nargin < 2
        reporting = PTKReportingDefault;
    end
    
    photometric_interpretation = header.PhotometricInterpretation;
    if ~(strcmp(photometric_interpretation, 'RGB') || strcmp(photometric_interpretation, 'MONOCHROME1') || strcmp(photometric_interpretation, 'MONOCHROME2'))
        reporting.Error('PTKReconstructDicomImageFromHeader:UnsupportedPhotometricInterpretation', 'Jpeg Dicom images are not supported');
    end
    
    rows = header.Rows;
    cols = header.Columns;
    samples_per_pixel = header.SamplesPerPixel;
    
    % Planar configuration defaults to interlaced (0)
    if isfield(header, 'PlanarConfiguration')
        planar_configuration = header.PlanarConfiguration;
    else
        planar_configuration = 0;
    end
    
    bits_allocated = header.BitsAllocated;
    bits_stored = header.BitsStored;
    high_bit = header.HighBit;
    
    if isfield(header, 'PixelRepresentation')
        pixel_representation = header.PixelRepresentation;
    else
        pixel_representation = 0; % Default unsigned
    end
    
    if isfield(header, 'NumberOfFrames')
        number_of_frames = header.NumberOfFrames;
    else
        number_of_frames = 1;
    end
    
    data_type_size = bits_allocated;
    if pixel_representation == 0 % unsigned
        if data_type_size == 8
            data_type = 'uint8';
        elseif data_type_size == 16
            data_type = 'uint16';
        else
            error('Unsupported number of bits allocated');
        end
    else % signed
        if data_type_size == 8
            data_type = 'int8';
        elseif data_type_size == 16
            data_type = 'int16';
        else
            error('Unsupported number of bits allocated');
        end
    end
    
    
    % Note the file endian may have changed during parsing, because that's
    % the way Dicom works
    if is_little_endian
        file_endian = PTKEndian.LittleEndian;
    else
        file_endian = PTKEndian.BigEndian;
    end
    
    % When typecasting, we need to check the computer's endian-ness so we know
    % whether to flip the bytes round or not
    computer_endian = PTKSystemUtilities.GetComputerEndian;
    file_endian_matches_computer_endian = (computer_endian == file_endian);
    
    % Flip endian if necessary
    pixel_data = typecast(header.PixelData, data_type);
    if ~file_endian_matches_computer_endian
        pixel_data = swapbytes(pixel_data);
    end
    
    % Mask out high bits in 16-bit data
    if data_type_size == 16 && high_bit == 11
        bitset(pixel_data, 12, 0, data_type);
        bitset(pixel_data, 13, 0, data_type);
        bitset(pixel_data, 14, 0, data_type);
        bitset(pixel_data, 15, 0, data_type);
        bitset(pixel_data, 16, 0, data_type);
    end
    
    pixel_data_zeros = zeros([cols, rows, samples_per_pixel, number_of_frames], data_type);
    
    if ((planar_configuration == 0) && (samples_per_pixel == 3))
        % Interlaced RGB data
        if number_of_frames > 1
            reporting.Error('PTKReconstructDicomImageFromHeader:UnsupportedNumberOfFrames', 'This function cannot read multiframe interlaced RGB images');
        end
        words_in_channel = int32(rows)*int32(cols);
        pixel_data_zeros(1 : words_in_channel) = pixel_data(1 : 3 : words_in_channel*3 - 2);
        pixel_data_zeros(words_in_channel + 1 : 2*words_in_channel) = pixel_data(2 : 3 : words_in_channel*3 - 1);
        pixel_data_zeros(2*words_in_channel + 1 : 3*words_in_channel) = pixel_data(3 : 3 : words_in_channel*3 - 0);
    else
        pixel_data_zeros(:) = pixel_data;
    end
    pixel_data_zeros = permute(pixel_data_zeros, [2 1 3]);
    image_data = pixel_data_zeros;
end