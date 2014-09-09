classdef PTKMaximumFissurePointsHorizontal < PTKPlugin
    % PTKMaximumFissurePointsHorizontal. Plugin which is part of the lobar segmentation.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKMaximumFissurePointsHorizontal is an intermediate stage in segmenting the
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
        ButtonText = 'Fissureness <br>Maxima Horizontal'
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
            fissureness_roi = application.GetResult('PTKFissurenessROIHorizontal');
            lung_mask = application.GetResult('PTKLobesFromFissurePlaneOblique');
                        
            results = PTKMaximumFissurePointsHorizontal.GetResultsForLung(fissure_approximation, fissureness_roi.RightMidFissure, application.GetResult('PTKGetRightLungROI'), lung_mask, 1, 3, reporting);
            results.ResizeToMatch(fissure_approximation);
            results.ImageType = PTKImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        
        function results = GetResultsForLung(fissure_approximation, fissureness_roi, lung_roi, lung_mask, lung_colour, fissure_colour, reporting)
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == lung_colour));
            
            fissure_approximation.ResizeToMatch(lung_roi);
            fissureness_roi.ResizeToMatch(lung_roi);
            lung_mask.ResizeToMatch(lung_roi);
            lung_mask.ResizeToMatch(lung_roi);
            
            [max_fissure_indices, ref_image] = PTKGetMaxFissurePoints(fissure_approximation.RawImage == fissure_colour, lung_mask, fissureness_roi, lung_roi, lung_roi.ImageSize);
            
            max_fissure_indices = [];
            if isempty(max_fissure_indices)
                reporting.ShowWarning('PTKMaximumFissurePointsHorizontal:FissurePointsNotFound', ['The horizontal fissure could not be found.']);
            end
            
            ref_image(ref_image == 1) = 8;
            
            results = lung_roi.BlankCopy;
            results.ChangeRawImage(ref_image);
        end
        
    end
end