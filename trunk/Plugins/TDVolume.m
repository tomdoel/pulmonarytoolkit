classdef TDVolume < TDPlugin
    % TDVolume. Plugin for computing left and right lung volumes
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDVolume computes the volume of the left and right lungs using the 
    %     lung segmentations and voxel sizes. The vessels and bronchi are 
    %     excluded up to the point where they enter the lung region.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Volume'
        ToolTip = 'Measures lung volumes'
        Category = 'Analysis'

        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(application, reporting)
            left_and_right_lungs = application.GetResult('TDLeftAndRightLungs');
            roi = application.GetResult('TDLungROI');
            
            left_lung = left_and_right_lungs.RawImage == 2;
            right_lung = left_and_right_lungs.RawImage == 1;
            
            voxel_size = roi.VoxelSize;

            left_results = TDVolume.Analyse(roi, left_lung);
            right_results = TDVolume.Analyse(roi, right_lung);
            combined_results = [];
            combined_results.lung_volume_mm3 = left_results.lung_volume_mm3 + right_results.lung_volume_mm3;
            combined_results.surface_volume_mm3 = left_results.surface_volume_mm3 + right_results.surface_volume_mm3;

            disp('*****');            
            disp(['  Voxel size: ' num2str(voxel_size(1), '%3.2f') 'mm x ' num2str(voxel_size(2), '%3.2f') 'mm x ' num2str(voxel_size(3), '%3.2f') 'mm']);
            disp(['  LEFT LUNG: Volume: ' num2str(left_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(left_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);
            disp(['  RIGHT LUNG: Volume: ' num2str(right_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(right_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);
            disp(['  BOTH LUNGS: Volume: ' num2str(combined_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(combined_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);            

            results = [];
        end
    end
    
    methods (Static, Access = private)
        function results = Analyse(lung_image, mask)
            results = [];
            
            voxel_size = lung_image.VoxelSize;
            results.voxel_size = voxel_size;
            
            voxel_volume_mm3 = voxel_size(1) * voxel_size(2) * voxel_size(3);
            lung_volume_mm3 = sum(mask(:))*voxel_volume_mm3;
            results.lung_volume_mm3 = lung_volume_mm3;
            
            surface = TDGetSurfaceFromSegmentation(mask);
            surface_volume_mm3 = sum(surface(:))*voxel_volume_mm3;
            results.surface_volume_mm3 = surface_volume_mm3;
        end
    end
end