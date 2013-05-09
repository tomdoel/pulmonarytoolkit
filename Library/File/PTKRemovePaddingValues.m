function PTKRemovePaddingValues(image_wrapper, metadata, reporting)
    % Replace padding value with zero
    if (isfield(metadata, 'PixelPaddingValue'))
        padding_value = metadata.PixelPaddingValue;
        
        padding_indices = find(image_wrapper.RawImage == padding_value);
        if (~isempty(padding_indices))
            reporting.ShowMessage('PTKLoadImageFromDicomFiles:ReplacingPaddingValue', ['Replacing padding value ' num2str(padding_value) ' with zeros.']);
            image_wrapper.RawImage(padding_indices) = 0;
        end
    end
    
    % Check for unspecified padding value in GE images
    if strcmp(metadata.Manufacturer, 'GE MEDICAL SYSTEMS')
        extra_padding_pixels = find(image_wrapper.RawImage == -2000);
        if ~isempty(extra_padding_pixels) && (metadata.PixelPaddingValue ~= -2000)
            reporting.ShowWarning('PTKLoadImageFromDicomFiles:IncorrectPixelPadding', 'This image is from a GE scanner and appears to have an incorrect PixelPaddingValue. This is a known issue with the some GE scanners. I am assuming the padding value is -2000 and replacing with zero.', []);
            image_wrapper.RawImage(extra_padding_pixels) = 0;
        end
    end    
end
