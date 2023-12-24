function [metrics, emphysema_mask] = PTKComputeEmphysemaFromMask(roi_data, mask)
    % Compute emphysema percentage and percentile density
    %
    % Syntax:
    %     metrics = PTKComputeEmphysemaFromMask(roi_data, mask);
    %
    %     [metrics, emphysema_mask] = PTKComputeEmphysemaFromMask(roi_data, mask);
    %
    % Parameters:
    %     roi_data (PTKImage):
    %         the imaged data. This can optionally cropped to the ROI
    %     mask (PTKImage):
    %         binary mask defining the context of the image (the region of interest).
    %         Only voxels in the mask are included in the computation
    %
    % Returns:
    %     metrics (PTKMetrics):
    %         contains the results of the emphysema computation
    %     emphysema_mask (PTKImage):
    %         a binary mask of voxels which have values in the emphsyema threshold
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    
    emphysema_threshold_value_hu_1 = -950;
    emphysema_threshold_value_hu_2 = -910;
    
    emphysema_threshold_value_1 = roi_data.HounsfieldToGreyscale(emphysema_threshold_value_hu_1);
    emphysema_threshold_value_2 = roi_data.HounsfieldToGreyscale(emphysema_threshold_value_hu_2);
    emphysema_threshold_value_percentile = 15;
    lower_threshold = (roi_data.RawImage <= emphysema_threshold_value_1) & (mask.RawImage > 0);
    upper_threshold = (roi_data.RawImage <= emphysema_threshold_value_2) & (mask.RawImage > 0);
    emphysema_mask_raw = uint8(upper_threshold);
    emphysema_mask_raw(lower_threshold) = 3;
    emphysema_mask = mask.BlankCopy();
    emphysema_mask.ChangeRawImage(emphysema_mask_raw);
    
    number_of_voxels_in_mask = sum(mask.RawImage(:));
    emphysema_voxels_in_mask = sum(lower_threshold(:)); % We only count voxels in the lower threshold
    emphysema_percentage = 100*emphysema_voxels_in_mask/number_of_voxels_in_mask;
    
    if ~mask.ImageExists
        emphysema_percentile_density = NaN;
        emphysema_percentile_density_hu = NaN;
    else
        emphysema_percentile_density = prctile(roi_data.RawImage(mask.RawImage(:)), emphysema_threshold_value_percentile);
        emphysema_percentile_density_hu = roi_data.GreyscaleToHounsfield(emphysema_percentile_density);
    end
    
    metrics = PTKMetrics();
    metrics.AddMetric('EmphysemaPercentage', emphysema_percentage, '% of emphysema');
    metrics.AddMetric('EmphysemaPercentileDensityHU', emphysema_percentile_density_hu, 'Emphysema percentile density (HU)');
end
