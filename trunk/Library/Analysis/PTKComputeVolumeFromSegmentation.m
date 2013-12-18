function results = PTKComputeVolumeFromSegmentation(segmentation_mask, reporting)
    % PTKComputeVolumeFromSegmentation. Computes volume and surface area from masks 
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.

    voxel_size = segmentation_mask.VoxelSize;
    
    voxel_volume_mm3 = voxel_size(1) * voxel_size(2) * voxel_size(3);
    lung_volume_mm3 = sum(segmentation_mask.RawImage(:) > 0)*voxel_volume_mm3;
    
    surface = PTKGetSurfaceFromSegmentation(segmentation_mask.RawImage);
    surface_volume_mm3 = sum(surface(:))*voxel_volume_mm3;
    
    results = PTKMetrics;
    results.AddMetric('VolumeCm3', lung_volume_mm3/1000, 'Volume (cm^3)');
    results.AddMetric('SurfaceVolumeCm3', surface_volume_mm3/1000, 'Volume of surface voxels (cm^3)');
end