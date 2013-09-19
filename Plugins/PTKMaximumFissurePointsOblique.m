classdef PTKMaximumFissurePointsOblique < PTKPlugin
    % PTKMaximumFissurePointsOblique. Plugin which is part of the lobar segmentation.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKMaximumFissurePointsOblique is an intermediate stage in segmenting the
    %     lobes.
    %
    %     For more information, see 
    %     [Doel et al., Pulmonary lobe segmentation from CT images using
    %     fissureness, airways, vessels and multilevel B-splines, 2012]
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Fissureness <br>Maxima Oblique'
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
            fissureness_roi = application.GetResult('PTKFissurenessROIOblique');
            fissure_approximation = application.GetResult('PTKFissureApproximation');
            left_and_right_lungs = application.GetResult('PTKLeftAndRightLungs');
            
            results_left = PTKMaximumFissurePointsOblique.GetResultsForLung(fissure_approximation, fissureness_roi.LeftMainFissure, application.GetResult('PTKGetLeftLungROI'), left_and_right_lungs, 2, 6);
            results_right = PTKMaximumFissurePointsOblique.GetResultsForLung(fissure_approximation, fissureness_roi.RightMainFissure, application.GetResult('PTKGetRightLungROI'), left_and_right_lungs, 1, 2);
            
            results = PTKCombineLeftAndRightImages(application.GetTemplateImage(PTKContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = PTKImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        function results = GetResultsForLung(fissure_approximation, fissureness_roi, lung_roi, left_and_right_lungs, lung_colour, fissure_colour)
            lung_mask = left_and_right_lungs.Copy;
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == lung_colour));
            
            fissure_approximation = fissure_approximation.Copy;
            fissure_approximation.ResizeToMatch(lung_roi);
            lung_mask.ResizeToMatch(lung_roi);
            
            [~, ref_image] = PTKGetMaxFissurePoints(fissure_approximation.RawImage == fissure_colour, lung_mask, fissureness_roi, lung_roi.ImageSize);
            
            results = lung_roi.BlankCopy;
            results.ChangeRawImage(ref_image);
        end        
    end
end