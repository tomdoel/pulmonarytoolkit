function results = PTKComputeAirTissueFraction(roi, mask, reporting)
    % PTKComputeAirTissueFraction. Computes volume and surface area from masks
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.

    ct_air_hu = -1000;
    ct_water_hu = 0;
    
    % Get the density values from the image
    raw_values = roi.RawImage(mask.RawImage(:));
    
    % Convert to HU
    hu_values = roi.GreyscaleToHounsfield(raw_values);
    
    % Convert to g/ml
    density_gml = PTKConvertHuToDensity(hu_values);
    
    mean_density_gml = mean(density_gml);
    std_density_gml = std(density_gml);
    
    mean_density_hu = mean(double(hu_values));
    std_density_hu = std(double(hu_values));
    
    fraction_air = 100*mean_density_hu/(ct_air_hu - ct_water_hu);
    fraction_tissue = 100 - fraction_air;
    
    results = PTKComputeVolumeFromSegmentation(mask, reporting);
    volume = results.VolumeCm3;
    
    results.AddMetric('AirFractionPercent', fraction_air, '% of air');
    results.AddMetric('TissueFractionPercent', fraction_tissue, '% of tissue');
    results.AddMetric('AirVolumeCm3', volume*fraction_air/100, 'Volume of air (cm^3)');
    results.AddMetric('TissueVolumeCm3', volume*fraction_tissue/100, 'Volume of tissue (cm^3)');
    results.AddMetric('MeanDensityGml', mean_density_gml, 'Mean density (g/ml)');
    results.AddMetric('StdDensityGml', std_density_gml, 'Std of density (g/ml)');
    results.AddMetric('MeanDensityHu', mean_density_hu, 'Mean density (HU)');
    results.AddMetric('StdDensityHu', std_density_hu, 'Std of density (HU)');
end
