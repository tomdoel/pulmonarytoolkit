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
    
    % Converts to g/ml
    density_values_raw = PTKConvertHuToDensity(density_values_raw);
    
    % Updates the output image
    density_image.ChangeRawImage(density_values_raw);
    density_image.ImageType = PTKImageType.Grayscale;
end

