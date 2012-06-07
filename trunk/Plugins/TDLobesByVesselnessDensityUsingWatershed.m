classdef TDLobesByVesselnessDensityUsingWatershed < TDPlugin
    % TDLobesByVesselnessDensityUsingWatershed. Plugin which is part of the lobar segmentation.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDLobesByVesselnessDensityUsingWatershed is an intermediate stage in 
    %     segmenting the lobes. It generated an approximate lobar segmentation
    %     using a Meyer watershed fill on vesselness density seeded from airway
    %     points.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Lobes <br>Initial guess'
        ToolTip = 'Segments lobes using a Meyer watershed fill on vesselness density seeded from airway points'
        Category = 'Lobes'
        
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, reporting)
            left_and_right_lungs = dataset.GetResult('TDLeftAndRightLungs');
            vessel_density = dataset.GetResult('TDVesselDensity');
            vessel_density_raw = vessel_density.RawImage;
            min_vd = min(vessel_density_raw(:));
            max_vd = max(vessel_density_raw(:));
            scale = 30000/(max_vd - min_vd);
            vessel_density_raw = int16(scale*(vessel_density_raw - min_vd));
            vessel_density_raw = 30000 - vessel_density_raw;
            vessel_density.ChangeRawImage(vessel_density_raw);
            
            airways_by_lobe = dataset.GetResult('TDAirwaysLabelledByLobe');
            airways_by_lobe = airways_by_lobe.AirwaysByLobeImage;
            
            results_left = TDLobesByVesselnessDensityUsingWatershed.GetLeftLobes(dataset, left_and_right_lungs, vessel_density, airways_by_lobe);
            results_right = TDLobesByVesselnessDensityUsingWatershed.GetRightLobes(dataset, left_and_right_lungs, vessel_density, airways_by_lobe);
            results = TDCombineLeftAndRightImages(dataset.GetTemplateImage(TDContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = TDImageType.Colormap;
        end
        
    end
    
    methods (Static, Access = private)
        
        function results_left = GetLeftLobes(dataset, left_and_right_lungs, vessel_density, airways_by_lobe)
            left_lung_roi = dataset.GetResult('TDGetLeftLungROI');
            left_lung_mask = left_and_right_lungs.Copy;
            left_lung_mask.ResizeToMatch(left_lung_roi);
            left_lung_mask.ChangeRawImage(left_lung_mask.RawImage == 2);
            
            vessel_density = vessel_density.Copy;
            vessel_density.ResizeToMatch(left_lung_roi);
            vessel_density = vessel_density.RawImage;
            
            airways_by_lobe = airways_by_lobe.Copy;
            airways_by_lobe.ResizeToMatch(left_lung_roi);
            
            airways_by_lobe = TDLobesByVesselnessDensityUsingWatershed.DilateAirways(airways_by_lobe, [5 6]);
            airways_by_lobe = int8(5*(airways_by_lobe == 5) + 6*(airways_by_lobe == 6));
            airways_by_lobe(~(left_lung_mask.RawImage)) = -1;
            
            results_left = left_lung_mask.BlankCopy;
            
            results_raw = TDWatershedMeyerFromStartingPoints(vessel_density, airways_by_lobe);
            results_raw = max(0, results_raw);
            results_left.ChangeRawImage(results_raw);
            results_left.ImageType = TDImageType.Colormap;
        end
        
        
        function results_right = GetRightLobes(dataset, left_and_right_lungs, vessel_density, airways_by_lobe)
            right_lung_roi = dataset.GetResult('TDGetRightLungROI');
            right_lung_mask = left_and_right_lungs.Copy;
            right_lung_mask.ResizeToMatch(right_lung_roi);
            right_lung_mask.ChangeRawImage(right_lung_mask.RawImage == 1);
            
            vessel_density = vessel_density.Copy;
            vessel_density.ResizeToMatch(right_lung_roi);
            vessel_density = vessel_density.RawImage;
            
            airways_by_lobe = airways_by_lobe.Copy;
            airways_by_lobe.ResizeToMatch(right_lung_roi);
            
            airways_by_lobe = TDLobesByVesselnessDensityUsingWatershed.DilateAirways(airways_by_lobe, [1 2 4]);
            airways_by_lobe_1 = int8(1*(airways_by_lobe == 1) + 1*(airways_by_lobe == 2) + 4*(airways_by_lobe == 4));
            airways_by_lobe_1(~(right_lung_mask.RawImage)) = -1;
            
            results_right = right_lung_mask.BlankCopy;
            
            results_1 = TDWatershedMeyerFromStartingPoints(vessel_density, airways_by_lobe_1);
            
            airways_by_lobe_2 = int8(1*(airways_by_lobe == 1) + 2*(airways_by_lobe == 2));
            airways_by_lobe_2(~(right_lung_mask.RawImage)) = -1;
            airways_by_lobe_2(results_1 == 4) = -1;
            airways_by_lobe_2(results_1 == -2) = -2;
            
            
            results_2 = TDWatershedMeyerFromStartingPoints(vessel_density, airways_by_lobe_2);
            
            results_raw = results_1;
            results_raw(results_2 == 2) = 2;
            results_raw(results_2 == -2) = 0;
            
            
            results_right.ChangeRawImage(results_raw);
            results_right.ImageType = TDImageType.Colormap;
        end
        
        function dilated_airways = DilateAirways(airways, colour_range)
            dilated_airways = zeros(airways.ImageSize, 'int8');
            for colour = colour_range
                next_image = airways.Copy;
                next_image.ChangeRawImage(next_image.RawImage == colour);
                next_image.BinaryMorph(@imdilate, 5);
                dilated_airways = dilated_airways + colour*int8(next_image.RawImage);
            end
        end

    end

end




