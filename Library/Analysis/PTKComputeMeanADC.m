function results = PTKComputeMeanADC(adc, region_mask)
    % PTKComputeMeanADC. Computes the mean ADC over a given region
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.

    
    % ADC is only computed over voxels in the mask which have an ADC
    % signal - we exclude noisy voxels and ventilation defects
    adc_mask = adc.RawImage > 0;
    adc_mask = adc_mask & region_mask.RawImage > 0;
            
    adc_values = adc.RawImage(adc_mask(:));
    mean_adc = mean(adc_values);
    std_adc = std(adc_values);
            
    results = PTKMetrics;
    results.AddMetric('MeanADC', mean_adc, 'Mean ADC (cm^2 s^-1)');
    results.AddMetric('StdADC', std_adc, 'Standard deviation of ADC (cm^2 s^-1)');
end
