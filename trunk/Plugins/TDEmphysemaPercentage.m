classdef TDEmphysemaPercentage < TDPlugin
    % TDEmphysemaPercentage. Plugin for computing the percentage of emphysema
    %     voxels
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Emphysema'
        ToolTip = 'Measures percentages of emphysema-like voxels'
        Category = 'Analysis'

        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function emphysema_results = RunPlugin(dataset, reporting)
            left_and_right_lungs = dataset.GetResult('TDLeftAndRightLungs');
%             lobes = dataset.GetResult('TDLobesFromFissurePlane');
            lobes = dataset.GetResult('TDLobesByVesselnessDensityUsingWatershed');
            image_info = dataset.GetImageInfo;
            uid = image_info.ImageUid;

            roi = dataset.GetResult('TDLungROI');
            
            emphysema_results = TDEmphysemaPercentage.GetEmphysemaPercentage(left_and_right_lungs, lobes, uid, roi);
        end
        
        
        function results = GenerateImageFromResults(emphysema_results, ~, ~)
            results = emphysema_results.Image;
            results.ChangeRawImage(3*uint8(results.RawImage));
        end        
    end
    
    methods (Static, Access = private)
        function results = Analyse(roi_data, raw_mask)
            emphysema_threshold_value_hu = -950;
            emphysema_threshold_value = roi_data.HounsfieldToGreyscale(emphysema_threshold_value_hu);
            emphysema_threshold_value_percentile = 15;
            emphysema_mask = roi_data.RawImage <= emphysema_threshold_value;
            
            number_of_voxels_in_mask = sum(raw_mask(:));
            emphysema_voxels_in_mask = sum(emphysema_mask(raw_mask(:)));
            emphysema_percentage = 100*emphysema_voxels_in_mask/number_of_voxels_in_mask;
            
            emphysema_percentile_density = prctile(roi_data.RawImage(raw_mask(:)), emphysema_threshold_value_percentile);
            emphysema_percentile_density_hu = roi_data.GreyscaleToHounsfield(emphysema_percentile_density);
            
            results = [];
            results.EmphysemaPercentage = emphysema_percentage;
            results.EmphysemaPercentileDensityHU = emphysema_percentile_density_hu;
        end

        function WriteResults(file_id, text, results)
            TDEmphysemaPercentage.WriteToFileAndScreen(file_id, [text ' : Emphysema: ' num2str(results.EmphysemaPercentage, '%5.1f') '%, PD at 15%: ' num2str(results.EmphysemaPercentileDensityHU, '%5.1f') 'HU']);
        end

        function WriteToFileAndScreen(file_id, text)
            disp(text);
            fprintf(file_id, sprintf('%s\r\n', text));
        end
    
        function emphysema_results = GetEmphysemaPercentage(left_and_right_lungs, lobes, uid, roi)
            
            emphysema_image = roi.BlankCopy;
            emphysema_threshold_value_hu = -950;
            emphysema_threshold_value = roi.HounsfieldToGreyscale(emphysema_threshold_value_hu);
            emphysema_image.ChangeRawImage(roi.RawImage <= emphysema_threshold_value);
            
            whole_lung_results = TDEmphysemaPercentage.Analyse(roi, left_and_right_lungs.RawImage > 0);
            
            results = [];
                        
            left_results = TDEmphysemaPercentage.Analyse(roi, left_and_right_lungs.RawImage == 2);
            right_results = TDEmphysemaPercentage.Analyse(roi, left_and_right_lungs.RawImage == 1);
            
            ur_results = TDEmphysemaPercentage.Analyse(roi, lobes.RawImage == 1);
            mr_results = TDEmphysemaPercentage.Analyse(roi, lobes.RawImage == 2);
            lr_results = TDEmphysemaPercentage.Analyse(roi, lobes.RawImage == 4);
            ul_results = TDEmphysemaPercentage.Analyse(roi, lobes.RawImage == 5);
            ll_results = TDEmphysemaPercentage.Analyse(roi, lobes.RawImage == 6);
            
            results.Lung = whole_lung_results;
            results.Left = left_results;
            results.Right = right_results;
            results.UR = ur_results;
            results.MR = mr_results;
            results.LR = lr_results;
            results.UL = ul_results;
            results.LL = ll_results;

            results_directory = PTKMain.GetResultsDirectoryAndCreateIfNecessary;
            file_name = fullfile(results_directory, uid);
            if ~exist(file_name, 'dir')
                mkdir(file_name);
            end      
            file_name = fullfile(file_name, 'TDEmphysemaPercentage.txt');
            file_handle = fopen(file_name, 'w');
            disp('*****');
            TDEmphysemaPercentage.WriteResults(file_handle, 'LUNG', results.Lung);
            disp('-');
            TDEmphysemaPercentage.WriteResults(file_handle, 'LEFT LUNG', results.Left);
            TDEmphysemaPercentage.WriteResults(file_handle, 'RIGHT LUNG', results.Right);
            disp('-');
            TDEmphysemaPercentage.WriteResults(file_handle, 'UR', results.UR);
            TDEmphysemaPercentage.WriteResults(file_handle, 'MR', results.MR);
            TDEmphysemaPercentage.WriteResults(file_handle, 'LR', results.LR);
            TDEmphysemaPercentage.WriteResults(file_handle, 'UL', results.UL);
            TDEmphysemaPercentage.WriteResults(file_handle, 'LL', results.LL);
            
            fclose(file_handle);
            emphysema_image.ImageType = TDImageType.Colormap;
            emphysema_results = [];
            emphysema_results.Image = emphysema_image;
            emphysema_results.Metrics = results;
        end
    end
end