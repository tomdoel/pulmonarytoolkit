classdef PTKFissurenessROIOblique < PTKPlugin
    % PTKFissurenessROIOblique. Plugin to determine fissureness with regions of interest
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     This is an intermediate stage towards lobar segmentation.
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
        ButtonText = 'Fissureness <br>ROI Oblique'
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
            
            fissure_approximation = application.GetResult('PTKFissureApproximation');
            
            left_and_right_lungs = application.GetResult('PTKLeftAndRightLungs');
            fissureness = application.GetResult('PTKFissureness');
            
            results_left = PTKFissurenessROIOblique.GetResultsForLung(fissure_approximation, application.GetResult('PTKGetLeftLungROI'), fissureness, 6, []);
            results_right = PTKFissurenessROIOblique.GetResultsForLung(fissure_approximation, application.GetResult('PTKGetRightLungROI'), fissureness, 2, 3);
            results = [];
            results.LeftMainFissure = results_left;
            results.RightMainFissure = results_right;
            results.LeftAndRightLungs = left_and_right_lungs;
        end
        
        function combined_image = GenerateImageFromResults(results, image_templates, ~)
            template_image = image_templates.GetTemplateImage(PTKContext.LungROI);

            results_left = results.LeftMainFissure;
            results_right = results.RightMainFissure;
            left_and_right_lungs = results.LeftAndRightLungs;
            
            combined_image = PTKCombineLeftAndRightImages(template_image, results_left, results_right, left_and_right_lungs);
            combined_image.ImageType = PTKImageType.Scaled;
        end
    end    
    
    methods (Static, Access = private)
        function results = GetResultsForLung(fissure_approximation, lung_roi, fissureness, main_fissure_colour, mid_fissure_colour)
            fissureness = fissureness.Copy;
            fissureness.ResizeToMatch(lung_roi);

            fissure_approximation = fissure_approximation.Copy;
            fissure_approximation.ResizeToMatch(lung_roi);

            fissure = fissure_approximation.RawImage == main_fissure_colour;
            fissure_dt = bwdist(fissure).*max(lung_roi.VoxelSize);
            
            distance_thresholded = max(0, fissure_dt - 20)/20;
            multiplier = max(0, 1 - distance_thresholded.^2);

            if isempty(mid_fissure_colour)
                fissureness = fissureness.RawImage.*multiplier;
            else
                % The suppressor is a term that dampens fissureness near the *other*
                % fissure, while the multiplier dampens fissureness far away from
                % the fissure we are looking for
                RM_fissure = fissure_approximation.RawImage == mid_fissure_colour;
                RM_fissure_dt = bwdist(RM_fissure).*max(lung_roi.VoxelSize);
                supressor_distance_thresholded_M = max(0, RM_fissure_dt)/10;
                supressor_M = min(1, supressor_distance_thresholded_M.^2);
                
                fissureness = fissureness.RawImage.*multiplier.*supressor_M;
            end

            results = lung_roi.BlankCopy;
            results.ChangeRawImage(fissureness);
        end
    end
end