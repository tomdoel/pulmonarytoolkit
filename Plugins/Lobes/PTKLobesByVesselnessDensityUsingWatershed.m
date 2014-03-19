classdef PTKLobesByVesselnessDensityUsingWatershed < PTKPlugin
    % PTKLobesByVesselnessDensityUsingWatershed. Plugin which is part of the lobar segmentation.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKLobesByVesselnessDensityUsingWatershed is an intermediate stage in 
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
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Visibility = 'Developer'
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, reporting)
            left_and_right_lungs = dataset.GetResult('PTKLeftAndRightLungs');
            vessel_density = dataset.GetResult('PTKVesselDensity');
            vessel_density_raw = vessel_density.RawImage;
            min_vd = min(vessel_density_raw(:));
            max_vd = max(vessel_density_raw(:));
            scale = 30000/(max_vd - min_vd);
            vessel_density_raw = int16(scale*(vessel_density_raw - min_vd));
            vessel_density_raw = 30000 - vessel_density_raw;
            vessel_density.ChangeRawImage(vessel_density_raw);
            
            airways_by_lobe = dataset.GetResult('PTKAirwaysLabelledByLobe');
            airways_by_lobe = airways_by_lobe.AirwaysByLobeImage;
            
            results_left = PTKLobesByVesselnessDensityUsingWatershed.GetLeftLobes(dataset, left_and_right_lungs, vessel_density, airways_by_lobe);
            results_right = PTKLobesByVesselnessDensityUsingWatershed.GetRightLobes(dataset, left_and_right_lungs, vessel_density, airways_by_lobe);
            results = PTKCombineLeftAndRightImages(dataset.GetTemplateImage(PTKContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = PTKImageType.Colormap;
        end
        
    end
    
    methods (Static, Access = private)
        
        function results_left = GetLeftLobes(dataset, left_and_right_lungs, vessel_density, airways_by_lobe)
            left_lung_roi = dataset.GetResult('PTKGetLeftLungROI');
            left_lung_mask = left_and_right_lungs.Copy;
            left_lung_mask.ResizeToMatch(left_lung_roi);
            left_lung_mask.ChangeRawImage(left_lung_mask.RawImage == 2);
            
            vessel_density = vessel_density.Copy;
            vessel_density.ResizeToMatch(left_lung_roi);
            vessel_density = vessel_density.RawImage;
            
            airways_by_lobe = airways_by_lobe.Copy;
            airways_by_lobe.ResizeToMatch(left_lung_roi);
            
            airways_by_lobe = PTKLobesByVesselnessDensityUsingWatershed.DilateAirwaysAndIntialWatershed(airways_by_lobe, [5 6], left_lung_mask, vessel_density);
            airways_by_lobe = int8(5*(airways_by_lobe == 5) + 6*(airways_by_lobe == 6));
            airways_by_lobe(~(left_lung_mask.RawImage)) = -1;
            
            results_left = left_lung_mask.BlankCopy;
            
            results_raw = PTKWatershedMeyerFromStartingPoints(vessel_density, airways_by_lobe);
            results_raw = max(0, results_raw);
            results_left.ChangeRawImage(results_raw);
            results_left.ImageType = PTKImageType.Colormap;
        end
        
        
        function results_right = GetRightLobes(dataset, left_and_right_lungs, vessel_density, airways_by_lobe)
            right_lung_roi = dataset.GetResult('PTKGetRightLungROI');
            right_lung_mask = left_and_right_lungs.Copy;
            right_lung_mask.ResizeToMatch(right_lung_roi);
            right_lung_mask.ChangeRawImage(right_lung_mask.RawImage == 1);
            
            vessel_density = vessel_density.Copy;
            vessel_density.ResizeToMatch(right_lung_roi);
            vessel_density = vessel_density.RawImage;
            
            airways_by_lobe = airways_by_lobe.Copy;
            airways_by_lobe.ResizeToMatch(right_lung_roi);
            
            airways_by_lobe = PTKLobesByVesselnessDensityUsingWatershed.DilateAirwaysAndIntialWatershed(airways_by_lobe, [1 2 4], right_lung_mask, vessel_density);
            airways_by_lobe_1 = int8(1*(airways_by_lobe == 1) + 1*(airways_by_lobe == 2) + 4*(airways_by_lobe == 4));
            airways_by_lobe_1(~(right_lung_mask.RawImage)) = -1;
            
            results_right = right_lung_mask.BlankCopy;
            
            results_1 = PTKWatershedMeyerFromStartingPoints(vessel_density, airways_by_lobe_1);
            
            airways_by_lobe_2 = int8(1*(airways_by_lobe == 1) + 2*(airways_by_lobe == 2));
            airways_by_lobe_2(~(right_lung_mask.RawImage)) = -1;
            airways_by_lobe_2(results_1 == 4) = -1;
            airways_by_lobe_2(results_1 == -2) = -2;
            
            
            results_2 = PTKWatershedMeyerFromStartingPoints(vessel_density, airways_by_lobe_2);
            
            results_raw = results_1;
            results_raw(results_2 == 2) = 2;
            results_raw(results_2 == -2) = 0;
            
            
            results_right.ChangeRawImage(results_raw);
            results_right.ImageType = PTKImageType.Colormap;
        end
        
        % To ensure each set of airways gets a chance to grow without getting
        % trapped in a local region of high-vesselness, dilate each airway and
        % then allow it to grow according to the vessel density for a limited
        % number of iterations (controlled by the initial_volume parameter)
        function dilated_airways = DilateAirwaysAndIntialWatershed(airways, colour_range, lung_mask, vessel_density)
            initial_volume_mm3 = 4000;
            max_iterations = round(initial_volume_mm3/prod(lung_mask.VoxelSize));
            dilated_airways = zeros(airways.ImageSize, 'int8');
            for colour = colour_range
                next_image = airways.Copy;
                next_image.ChangeRawImage(next_image.GetMappedRawImage == colour);
                
                % Dilate the airways
                next_image.BinaryMorph(@imdilate, 5);

                % Now perform a watershed for a limited number of iterations
                airways_by_lobe = int8(next_image.RawImage);
                airways_by_lobe(~(lung_mask.RawImage)) = -1;
                results = PTKWatershedMeyerFromStartingPoints(vessel_density, airways_by_lobe, max_iterations);
                dilated_airways = dilated_airways + colour*int8(results == 1);
            end
        end

    end

end




