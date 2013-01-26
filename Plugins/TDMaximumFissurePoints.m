classdef TDMaximumFissurePoints < TDPlugin
    % TDMaximumFissurePoints. Plugin which is part of the lobar segmentation.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDMaximumFissurePoints is an intermediate stage in segmenting the
    %     lobes.
    %
    %     For more information, see 
    %     [Doel et al., Pulmonary lobe segmentation from CT images using
    %     fissureness, airways, vessels and multilevel B-splines, 2012]
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Fissureness <br>Maxima'
        ToolTip = ''
        Category = 'Fissures'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(application, reporting)
            fissure_approximation = application.GetResult('TDFissureApproximation');
            
            left_and_right_lungs = application.GetResult('TDLeftAndRightLungs');
            
            
            results_left = TDMaximumFissurePoints.GetLeftLungResults(application, fissure_approximation);
            results_right = TDMaximumFissurePoints.GetRightLungResults(application, fissure_approximation);
            
            results = TDCombineLeftAndRightImages(application.GetTemplateImage(TDContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = TDImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        function left_results = GetLeftLungResults(application, fissure_approximation)
            fissureness_roi = application.GetResult('TDFissurenessROI');
            
            lung_mask = application.GetResult('TDLeftAndRightLungs');
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == 2));
            
            left_lung_roi = application.GetResult('TDGetLeftLungROI');
            fissure_approximation = fissure_approximation.Copy;
            fissure_approximation.ResizeToMatch(left_lung_roi);
            lung_mask.ResizeToMatch(left_lung_roi);
            
            [high_fissure_indices, ref_image] = TDGetMaxFissurePoints(fissure_approximation.RawImage == 6, lung_mask, fissureness_roi.LeftMainFissure, left_lung_roi.ImageSize);
            
            left_results = left_lung_roi.BlankCopy;
            left_results.ChangeRawImage(ref_image);
        end
        
        function right_results = GetRightLungResults(application, fissure_approximation)
            fissureness_roi = application.GetResult('TDFissurenessROI');
            
            lung_mask = application.GetResult('TDLeftAndRightLungs');
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == 1));
            
            right_lung_roi = application.GetResult('TDGetRightLungROI');
            fissure_approximation = fissure_approximation.Copy;
            fissure_approximation.ResizeToMatch(right_lung_roi);
            lung_mask.ResizeToMatch(right_lung_roi);
            
            [high_fissure_indices, ref_image_o] = TDGetMaxFissurePoints(fissure_approximation.RawImage == 2, lung_mask, fissureness_roi.RightMainFissure, right_lung_roi.ImageSize);

            [high_fissure_indices_m, ref_image_m] = TDGetMaxFissurePoints(fissure_approximation.RawImage == 3, lung_mask, fissureness_roi.RightMidFissure, right_lung_roi.ImageSize);
            
            ref_image = ref_image_m;
            ref_image(ref_image_o == 1) = 1;
            ref_image(ref_image_m == 1) = 8;
            
            right_results = right_lung_roi.BlankCopy;
            right_results.ChangeRawImage(ref_image);
        end
    end
end