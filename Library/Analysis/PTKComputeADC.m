function adc = PTKComputeADC(weighted_image_1, weighted_image_2, bvalue_1, bvalue_2, max_value)
    % PTKComputeADC. Computes an ADC image from two images with weighted diffusion.
    %
    % Inputs:
    %     weighted_image_1 - weighted diffusion image or unweighted ventilation image in a PTKImage class
    %     weighted_image_2 - weighted diffusion image or unweighted ventilation image in a PTKImage class
    %     b_value_1 - the comptued b_value of weighted_image_1 (zero for an unweighted image)
    %     b_value_2 - the comptued b_value of weighted_image_2 (zero for an unweighted image)
    %     max_value - Threshold for the maximum allowed value in the output ADC.
    %          Values above this are assumed to be noise and set to zero
    %
    % Outputs:
    %     adc - a PTKImage containing the computed ADC values at each voxel
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    adc = weighted_image_1.BlankCopy;
    S1 = double(weighted_image_1.RawImage);
    S2 = double(weighted_image_2.RawImage);
    
    adc_raw = (1/(bvalue_2 - bvalue_1))*log(S1./S2);
    adc_raw(isinf(adc_raw)) = 0;
    adc_raw(isnan(adc_raw)) = 0;
   
    adc_raw(adc_raw < 0) = 0;
    
    if ~isempty(max_value)
        adc_raw(adc_raw > max_value) = 0;
    end
    
    adc.ChangeRawImage(adc_raw);
    adc.ImageType = PTKImageType.Scaled;
end
