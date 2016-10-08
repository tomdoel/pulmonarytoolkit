function new_padding_value = PTKRemovePaddingValues(image_wrapper, metadata, reporting)

    new_padding_value = [];
    padding_indices = [];
    
    % Replace padding value with zero
    if (isfield(metadata, 'PixelPaddingValue'))
        padding_value = metadata.PixelPaddingValue;
        
        padding_indices = find(image_wrapper.RawImage == padding_value);
    end
    
    % Check for unspecified padding value in GE images
    if isfield(metadata, 'Manufacturer')
        if strcmp(metadata.Manufacturer, 'GE MEDICAL SYSTEMS')
            padding_indices = find(image_wrapper.RawImage == -2000);
        end
    end
    
    if ~isempty(padding_indices)
        image_wrapper.RawImage(padding_indices) = max(image_wrapper.RawImage(:));
        new_padding_value = min(image_wrapper.RawImage(:)) - 1;
        image_wrapper.RawImage(padding_indices) = new_padding_value;
    end
end
