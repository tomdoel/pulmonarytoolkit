classdef PTKFissurenessROI < PTKPlugin
    % PTKFissurenessROI. Plugin to determine fissureness with regions of interest
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     This is an intermediate stage towards lobar segmentation.
    %
    %     PTKFissurenessROI computes the fissureness modified by a distance
    %     transform from the approximate fissure curves generated using 
    %     PTKLobesByVesselnessDensityUsingWatershed.
    %
    %     For more information, see 
    %     [Doel et al., Pulmonary lobe segmentation from CT images using
    %     fissureness, airways, vessels and multilevel B-splines, 2012]
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Fissureness <br>ROI'
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
            fissureness = application.GetResult('PTKFissureness');
            
            results_left = PTKFissurenessROI.GetLeftLungResults(application, fissure_approximation, left_and_right_lungs, fissureness);
            [results_right, results_right_mid] = PTKFissurenessROI.GetRightLungResults(application, fissure_approximation, left_and_right_lungs, fissureness);
            results = [];
            results.LeftMainFissure = results_left;
            results.RightMainFissure = results_right;
            results.RightMidFissure = results_right_mid; 
            results.LeftAndRightLungs = left_and_right_lungs;
        end
        
        function combined_image = GenerateImageFromResults(results, image_templates, ~)
            template_image = image_templates.GetTemplateImage(PTKContext.LungROI);

            results_left = results.LeftMainFissure;
            results_right = results.RightMainFissure;
            results_midright = results.RightMidFissure;
            left_and_right_lungs = results.LeftAndRightLungs;
            
            combined_image = PTKCombineLeftAndRightImages(template_image, results_left, results_midright, left_and_right_lungs);
            combined_image.ImageType = PTKImageType.Scaled;
            
        end
    end    
    
    methods (Static, Access = private)
        function left_results = GetLeftLungResults(application, fissure_approximation, left_and_right_lungs, fissureness)
            left_lung_roi = application.GetResult('PTKGetLeftLungROI');
            left_results = left_lung_roi.BlankCopy;
            
            fissure_approximation = fissure_approximation.Copy;
            fissure_approximation.ResizeToMatch(left_lung_roi);
            L_fissure = fissure_approximation.RawImage == 6;
            
            fissureness = fissureness.Copy;
            fissureness.ResizeToMatch(left_lung_roi);
            L_fissure_dt = bwdist(L_fissure);
            
            distance_thresholded = max(0, L_fissure_dt - 15)/30;
            multiplier = max(0, 1 - distance_thresholded.^2);
            fissureness = fissureness.RawImage.*multiplier;

            left_results.ChangeRawImage(fissureness);
        end
        
        function [results_right, results_right_mid] = GetRightLungResults(application, fissure_approximation, left_and_right_lungs, fissureness)
            right_lung_roi = application.GetResult('PTKGetRightLungROI');
            fissureness = fissureness.Copy;
            fissureness.ResizeToMatch(right_lung_roi);

            fissure_approximation = fissure_approximation.Copy;
            fissure_approximation.ResizeToMatch(right_lung_roi);

            R_fissure = fissure_approximation.RawImage == 2;
            R_fissure_dt = bwdist(R_fissure);
            
            distance_thresholded = max(0, R_fissure_dt - 15)/30;
            multiplier = max(0, 1 - distance_thresholded.^2);
            supressor_distance_thresholded = max(0, R_fissure_dt)/20;
            supressor = min(1, supressor_distance_thresholded.^2);

            RM_fissure = fissure_approximation.RawImage == 3;
            
            RM_fissure_dt = bwdist(RM_fissure);
            distance_thresholded_M = max(0, RM_fissure_dt - 20)/40;
            multiplier_M = max(0, 1 - distance_thresholded_M.^2);
            multiplier_M = multiplier_M.*single(~R_fissure);
            
            supressor_distance_thresholded_M = max(0, RM_fissure_dt)/20;
            supressor_M = min(1, supressor_distance_thresholded_M.^2);
            
            % The suppressor is a term that dampens fissureness near the *other*
            % fissure, while the multiplier dampens fissureness far away from
            % the fissure we are looking for
            
            fissureness_UL = fissureness.RawImage.*multiplier.*supressor_M;
            fissureness_M = fissureness.RawImage.*multiplier_M.*supressor;

            results_right = right_lung_roi.BlankCopy;
            results_right.ChangeRawImage(fissureness_UL);

            results_right_mid = right_lung_roi.BlankCopy;
            results_right_mid.ChangeRawImage(fissureness_M);
        end
    end
end