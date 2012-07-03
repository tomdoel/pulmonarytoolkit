function density_image = TDConvertCTToDensity(ct_image)
    density_image = ct_image.BlankCopy;
    
    % Find the raw values
    density_values_raw = ct_image.RawImage;
    
    % Convert to HU
    density_values_raw = double(ct_image.GreyscaleToHounsfield(double(density_values_raw)));
    
    % Convert to density mg/mL
    density_values_raw = density_values_raw + 1000;

    density_image.ChangeRawImage(density_values_raw);
    density_image.ImageType = TDImageType.Grayscale;
    
end

