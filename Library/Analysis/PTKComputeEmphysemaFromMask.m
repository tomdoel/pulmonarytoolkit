function [metrics, emphysema_mask] = PTKComputeEmphysemaFromMask(roi_data, mask)
    % PTKComputeEmphysemaFromMask. Computes emphysema percentage and percentile
    % density
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    
    emphysema_threshold_value_hu = -950;
    emphysema_threshold_value = roi_data.HounsfieldToGreyscale(emphysema_threshold_value_hu);
    emphysema_threshold_value_percentile = 15;
    emphysema_mask_raw = (roi_data.RawImage <= emphysema_threshold_value) & (mask.RawImage > 0);
    emphysema_mask = mask.BlankCopy;
    emphysema_mask.ChangeRawImage(emphysema_mask_raw);
    
    number_of_voxels_in_mask = sum(mask.RawImage(:));
    emphysema_voxels_in_mask = sum(emphysema_mask_raw(mask.RawImage(:)));
    emphysema_percentage = 100*emphysema_voxels_in_mask/number_of_voxels_in_mask;
    
    if ~mask.ImageExists
        emphysema_percentile_density = NaN;
        emphysema_percentile_density_hu = NaN;
    else
        emphysema_percentile_density = prctile(roi_data.RawImage(mask.RawImage(:)), emphysema_threshold_value_percentile);
        emphysema_percentile_density_hu = roi_data.GreyscaleToHounsfield(emphysema_percentile_density);
    end
    
    metrics = PTKMetrics;
    metrics.AddMetric('EmphysemaPercentage', emphysema_percentage, '% of emphysema');
    metrics.AddMetric('EmphysemaPercentileDensityHU', emphysema_percentile_density_hu, 'Emphysema percentile density (HU)');
end