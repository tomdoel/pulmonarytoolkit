function density_values_g_ml = PTKConvertHuToDensity(hu_values)
    % PTKConvertHuToDensity. Converts density values in HU to g/ml
    %
    %     PTKConvertHuToDensity converts the HU values in the vector hu_values to
    %     the approximate values of mass density, assuming a linear
    %     relationshoip between radiodensity values and mass density.
    %
    %     Note: this is often a reasonable approximation, but it depends on the
    %     scanner and the material being scanned. 
    %
    %     The output will be a vector containing density values in g/mL.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    density_water_mgmL = 1000;
    density_air_stp_mgmL = 1.2922;
    HU_air = -1000;
    
    % Convert to density mg/mL
    % We are assuming a linear relationship between radiodensity and mass
    % density - in relaity this relationship depends on the material being
    % scanned and the calibration of the scanner
    alpha = (density_air_stp_mgmL - density_water_mgmL)/HU_air;
    density_values_mgml = alpha*double(hu_values) + density_water_mgmL;
    
    % Convert from mg/mL to g/ml
    density_values_g_ml = density_values_mgml/1000;
    
    % Because this linear relationship is an approximation, we might get
    % negative density values - threshold at zero
    density_values_g_ml = max(0, density_values_g_ml);
end

