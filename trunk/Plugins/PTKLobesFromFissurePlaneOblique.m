classdef PTKLobesFromFissurePlaneOblique < PTKPlugin
    % PTKLobesFromFissurePlaneOblique. Plugin which is part of the lobar segmentation.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKLobesFromFissurePlaneOblique is an intermediate stage in segmenting the
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
        ButtonText = 'Lobes Oblique'
        ToolTip = ''
        Category = 'Lobes'

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
            
            left_and_right_lungs = application.GetResult('PTKLeftAndRightLungs');
            fissure_plane = application.GetResult('PTKFissurePlaneOblique');
            lung_mask = application.GetResult('PTKLeftAndRightLungs');
            left_lung_template = application.GetTemplateImage(PTKContext.LeftLung).BlankCopy;
            right_lung_template = application.GetTemplateImage(PTKContext.RightLung).BlankCopy;
            results_left = PTKLobesFromFissurePlaneOblique.GetLeftLungResults(left_lung_template, lung_mask.Copy, fissure_plane.Copy, reporting);
            results_right = PTKLobesFromFissurePlaneOblique.GetRightLungResults(right_lung_template, lung_mask, fissure_plane, reporting);
            
            results = PTKCombineLeftAndRightImages(application.GetTemplateImage(PTKContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = PTKImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        function left_results = GetLeftLungResults(lung_template, lung_mask, fissure_plane, reporting)

            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == 2));
            
            lung_mask.ResizeToMatch(lung_template);
            
            
            fissure_plane.ResizeToMatch(lung_template);
            fissure_plane = find(fissure_plane.RawImage(:) == 4);
            
            left_results = PTKDivideVolumeUsingScatteredPoints(lung_mask, fissure_plane, 5, reporting);
            left_results.ChangeColourIndex(1, 5);
            left_results.ChangeColourIndex(2, 6);  
        end
        
        function results_right = GetRightLungResults(lung_template, lung_mask, fissure_plane, reporting)
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == 1));
            
            lung_mask.ResizeToMatch(lung_template);
            fissure_plane.ResizeToMatch(lung_template);
            fissure_plane_o = find(fissure_plane.RawImage(:) == 3);
            
            results_right = PTKDivideVolumeUsingScatteredPoints(lung_mask, fissure_plane_o, 5, reporting);
            results_right.ChangeColourIndex(2, 4);            
        end
    end
end