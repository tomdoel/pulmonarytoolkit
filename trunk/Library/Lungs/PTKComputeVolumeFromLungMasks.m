function results = TDComputeVolumeFromLungMasks(left_and_right_lungs, reporting)
    % TDComputeVolumeFromLungMasks. Computes volume and surface area from lung masks 
    %
    %     Lung masks have values of 1 for the right lung and 2 for the left lung
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
        
    left_lung = left_and_right_lungs.RawImage == 2;
    right_lung = left_and_right_lungs.RawImage == 1;
    
    voxel_size = left_and_right_lungs.VoxelSize;
    
    results = [];
    results.LeftLung = Analyse(voxel_size, left_lung);
    results.RightLung = Analyse(voxel_size, right_lung);
    results.BothLungs = [];
    results.BothLungs.LungVolumeMm3 = results.LeftLung.LungVolumeMm3 + results.RightLung.LungVolumeMm3;
    results.BothLungs.SurfaceVolumeMm3 = results.LeftLung.SurfaceVolumeMm3 + results.RightLung.SurfaceVolumeMm3;
    
    disp(['  Voxel size: ' num2str(voxel_size(1), '%3.2f') 'mm x ' num2str(voxel_size(2), '%3.2f') 'mm x ' num2str(voxel_size(3), '%3.2f') 'mm']);
    disp(['  LEFT LUNG: Volume: ' num2str(results.LeftLung.LungVolumeMm3/1000, '%7.0f') ' cm^3 error: ' num2str(results.LeftLung.SurfaceVolumeMm3/1000, '%7.0f') ' cm^3']);
    disp(['  RIGHT LUNG: Volume: ' num2str(results.RightLung.LungVolumeMm3/1000, '%7.0f') ' cm^3 error: ' num2str(results.RightLung.SurfaceVolumeMm3/1000, '%7.0f') ' cm^3']);
    disp(['  BOTH LUNGS: Volume: ' num2str(results.BothLungs.LungVolumeMm3/1000, '%7.0f') ' cm^3 error: ' num2str(results.BothLungs.SurfaceVolumeMm3/1000, '%7.0f') ' cm^3']);
    
end

function results = Analyse(voxel_size, mask)
    results = [];
    
    results.voxel_size = voxel_size;
    
    voxel_volume_mm3 = voxel_size(1) * voxel_size(2) * voxel_size(3);
    lung_volume_mm3 = sum(mask(:))*voxel_volume_mm3;
    results.LungVolumeMm3 = lung_volume_mm3;
    
    surface = TDGetSurfaceFromSegmentation(mask);
    surface_volume_mm3 = sum(surface(:))*voxel_volume_mm3;
    results.SurfaceVolumeMm3 = surface_volume_mm3;
end
