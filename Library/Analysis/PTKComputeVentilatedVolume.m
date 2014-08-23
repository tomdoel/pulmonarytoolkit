function results = PTKComputeVentilatedVolume(ventilation_mask, raw_region_mask)
    % PTKComputeVentilatedVolume. Computes the percentage of a region showing
    %     ventilation in gas MRI images
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.

    ventilation_mask_raw = ventilation_mask.RawImage > 0;
    ventilation_mask_raw = ventilation_mask_raw & raw_region_mask;
    
    sum_ventilated_voxels = sum(ventilation_mask_raw(:));
    sum_region_voxels = sum(raw_region_mask(:));
    
    percentage_ventilated = 100*sum_ventilated_voxels/sum_region_voxels;
    
    ventilated_volume_mm3 = sum_ventilated_voxels*prod(ventilation_mask.VoxelSize);

    results = PTKMetrics;
    results.AddMetric('VentilatedVolumePercent', percentage_ventilated, 'Ventilated volume (%)');
    results.AddMetric('VentilatedVolume', ventilated_volume_mm3/1000, 'ventilated Volume (cm^3)');
end
