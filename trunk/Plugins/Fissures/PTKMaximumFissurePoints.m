classdef PTKMaximumFissurePoints < PTKPlugin
    % PTKMaximumFissurePoints. Plugin which is part of the lobar segmentation.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKMaximumFissurePoints is an intermediate stage in segmenting the
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
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(application, reporting)
            fissure_approximation = application.GetResult('PTKFissureApproximation');
            
            left_and_right_lungs = application.GetResult('PTKLeftAndRightLungs');
            
            
            results_left = PTKMaximumFissurePoints.GetLeftLungResults(application, fissure_approximation);
            results_right = PTKMaximumFissurePoints.GetRightLungResults(application, fissure_approximation);
            
            results = PTKCombineLeftAndRightImages(application.GetTemplateImage(PTKContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = PTKImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        function left_results = GetLeftLungResults(application, fissure_approximation)
            fissureness_roi = application.GetResult('PTKFissurenessROI');
            
            lung_mask = application.GetResult('PTKLeftAndRightLungs');
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == 2));
            
            left_lung_roi = application.GetResult('PTKGetLeftLungROI');
            fissure_approximation = fissure_approximation.Copy;
            fissure_approximation.ResizeToMatch(left_lung_roi);
            lung_mask.ResizeToMatch(left_lung_roi);
            
            [high_fissure_indices, ref_image] = PTKGetMaxFissurePoints(fissure_approximation.RawImage == 6, lung_mask, fissureness_roi.LeftMainFissure, left_lung_roi, left_lung_roi.ImageSize);
            
            left_results = left_lung_roi.BlankCopy;
            left_results.ChangeRawImage(ref_image);
        end
        
        function right_results = GetRightLungResults(application, fissure_approximation)
            fissureness_roi = application.GetResult('PTKFissurenessROI');
            
            lung_mask = application.GetResult('PTKLeftAndRightLungs');
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == 1));
            
            right_lung_roi = application.GetResult('PTKGetRightLungROI');
            fissure_approximation = fissure_approximation.Copy;
            fissure_approximation.ResizeToMatch(right_lung_roi);
            lung_mask.ResizeToMatch(right_lung_roi);
            
            [high_fissure_indices, ref_image_o] = PTKGetMaxFissurePoints(fissure_approximation.RawImage == 2, lung_mask, fissureness_roi.RightMainFissure, right_lung_roi, right_lung_roi.ImageSize);

            [high_fissure_indices_m, ref_image_m] = PTKGetMaxFissurePoints(fissure_approximation.RawImage == 3, lung_mask, fissureness_roi.RightMidFissure, right_lung_roi, right_lung_roi.ImageSize);
            
            ref_image = ref_image_m;
            ref_image(ref_image_o == 1) = 1;
            ref_image(ref_image_m == 1) = 8;
            
            right_results = right_lung_roi.BlankCopy;
            right_results.ChangeRawImage(ref_image);
        end
    end
end