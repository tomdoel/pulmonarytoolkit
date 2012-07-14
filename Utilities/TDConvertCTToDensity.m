function density_image = TDConvertCTToDensity(ct_image)
    density_image = ct_image.BlankCopy;
    
    % Find the raw values
    density_values_raw = ct_image.RawImage;
    
    % Convert to HU
    density_values_raw = double(ct_image.GreyscaleToHounsfield(double(density_values_raw)));
    
    density_water_mgmL = 1000;
    density_air_stp_mgmL = 1.2922;
    HU_air = -1000;
    
    % Convert to density mg/mL
    % We are assuming a linear relationship between radiodensity and mass
    % density - in relaity this relationship depends on the material being
    % scanned and the calibration of the scanner
    alpha = (density_air_stp_mgmL - density_water_mgmL)/HU_air;
    density_values_raw = alpha*density_values_raw + density_water_mgmL;
    
    % Because this linear relationship is an approximation, we might get
    % negative density values - threshold at zero
    density_values_raw = max(0, density_values_raw);

    density_image.ChangeRawImage(density_values_raw);
    density_image.ImageType = TDImageType.Grayscale;
    
end

