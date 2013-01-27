function density_image = PTKConvertCTToDensity(ct_image)
    % PTKConvertCTToDensity. Converts image from Hounsfield Units to density
    %
    %     PTKConvertCTToDensity takes a CT image and converts the HU values to
    %     the approximate values of mass density, assuming a linear
    %     relationshoip between radiodensity values and mass density.
    %
    %     Note: this is often a reasonable approximation, but it depends on the
    %     scanner and the material being scanned. 
    %
    %     The input must be of type PTKImage, with values in Hounsfield Units.
    %
    %     The output will also be a PTKImage, containing density values in g/mL.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
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
    
    % Convert from mg/mL to g/ml
    density_values_raw = density_values_raw/1000;
    
    % Because this linear relationship is an approximation, we might get
    % negative density values - threshold at zero
    density_values_raw = max(0, density_values_raw);

    density_image.ChangeRawImage(density_values_raw);
    density_image.ImageType = PTKImageType.Grayscale;
end

