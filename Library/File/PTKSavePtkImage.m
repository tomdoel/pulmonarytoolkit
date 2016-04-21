function header_file = PTKSavePtkImage(image_data, file_path, file_name, compression, reporting)
    % PTKSavePtkRawImage. Saves a PTKImage to disk, separating and compressing pixel data
    % Optionally returns a header object which contains the image object without the image data, and with the
    % filename stored so that it can be reloaded using a call to LoadRawImage
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if ~isa(image_data, 'PTKImage')
        reporting.Error('PTKSavePtkImage:InputMustBePTKImage', 'Requires a PTKImage as input');
    end

    image_class = class(image_data.RawImage);

    if length(size(image_data.RawImage)) ~= 3
        % Compression currently only supports 3D images
        compression = [];
    else
        if ~MimDiskUtilities.CompressionSupported(compression, image_class, reporting)
            compression = [];
        end
    end
    
    raw_filename = [file_name '.raw'];
    
    % Create a header file if requested. The header is the image object
    % minus the raw image data, and contains the raw image filename
    if (nargout > 0)
        header_file = image_data.CreateHeader(raw_filename, compression);
    end
    
    PTKSavePtkRawImage(image_data.RawImage, file_path, raw_filename, compression, reporting);
end