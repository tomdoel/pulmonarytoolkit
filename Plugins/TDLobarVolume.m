classdef TDLobarVolume < TDPlugin
    % TDLobarVolume. Plugin for computing the lobar volumes
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDLobarVolume computes the volume of the lobes using the 
    %     lobe segmentations and voxel sizes. The vessels and bronchi are 
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
        ButtonText = 'Lobe Volume'
        ToolTip = 'Measures lobe volumes'
        Category = 'Analysis'

        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            left_and_right_lungs = dataset.GetResult('TDLeftAndRightLungs');
            roi = dataset.GetResult('TDLungROI');
            
            left_lung = left_and_right_lungs.RawImage == 2;
            right_lung = left_and_right_lungs.RawImage == 1;
            
            voxel_size = roi.VoxelSize;

            left_results = TDLobarVolume.Analyse(roi, left_lung);
            right_results = TDLobarVolume.Analyse(roi, right_lung);
            
            lobes = dataset.GetResult('TDLobesFromFissurePlane');
            ur_results = TDLobarVolume.Analyse(roi, lobes.RawImage == 1);
            mr_results = TDLobarVolume.Analyse(roi, lobes.RawImage == 2);
            lr_results = TDLobarVolume.Analyse(roi, lobes.RawImage == 4);
            ul_results = TDLobarVolume.Analyse(roi, lobes.RawImage == 5);
            ll_results = TDLobarVolume.Analyse(roi, lobes.RawImage == 6);
            
            
            
            
            combined_results = [];
            combined_results.lung_volume_mm3 = left_results.lung_volume_mm3 + right_results.lung_volume_mm3;
            combined_results.surface_volume_mm3 = left_results.surface_volume_mm3 + right_results.surface_volume_mm3;

            results_directory = TDPTK.GetResultsDirectoryAndCreateIfNecessary;
            image_info = dataset.GetImageInfo;
            uid = image_info.ImageUid;
            file_name = fullfile(results_directory, uid);
            if ~exist(file_name, 'dir')
                mkdir(file_name);
            end      
            file_name = fullfile(file_name, 'VolumeMeasurements.txt');
            file_handle = fopen(file_name, 'w');
            disp('*****');
            TDLobarVolume.WriteToFileAndScreen(file_handle, ['Voxel size: ' num2str(voxel_size(1), '%3.2f') 'mm x ' num2str(voxel_size(2), '%3.2f') 'mm x ' num2str(voxel_size(3), '%3.2f') 'mm']);
            TDLobarVolume.WriteToFileAndScreen(file_handle, ['LEFT LUNG : Volume: ' num2str(left_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(left_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);
            TDLobarVolume.WriteToFileAndScreen(file_handle, ['RIGHT LUNG: Volume: ' num2str(right_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(right_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);
            TDLobarVolume.WriteToFileAndScreen(file_handle, ['BOTH LUNGS: Volume: ' num2str(combined_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(combined_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);            
            disp('-');

            TDLobarVolume.WriteToFileAndScreen(file_handle, ['UPPER RIGHT LOBE : Volume: ' num2str(ur_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(ur_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);            
            TDLobarVolume.WriteToFileAndScreen(file_handle, ['MIDDLE RIGHT LOBE: Volume: ' num2str(mr_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(mr_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);            
            TDLobarVolume.WriteToFileAndScreen(file_handle, ['LOWER RIGHT LOBE : Volume: ' num2str(lr_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(lr_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);            
            TDLobarVolume.WriteToFileAndScreen(file_handle, ['UPPER LEFT LOBE  : Volume: ' num2str(ul_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(ul_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);            
            TDLobarVolume.WriteToFileAndScreen(file_handle, ['LOWER LEFT LOBE  : Volume: ' num2str(ll_results.lung_volume_mm3/1000, '%7.0f') ' cm^3 error: ' num2str(ll_results.surface_volume_mm3/1000, '%7.0f') ' cm^3']);            

            fclose(file_handle);
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
        
        function WriteToFileAndScreen(file_id, text)
            disp(text);
            fprintf(file_id, sprintf('%s\r\n', text));
        end
    end
end