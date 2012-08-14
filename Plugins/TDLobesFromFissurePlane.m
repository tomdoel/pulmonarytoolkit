classdef TDLobesFromFissurePlane < TDPlugin
    % TDLobesFromFissurePlane. Plugin which is part of the lobar segmentation.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDLobesFromFissurePlane is an intermediate stage in segmenting the
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
        ButtonText = 'Lobes'
        ToolTip = ''
        Category = 'Lobes'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(application, reporting)
            
            left_and_right_lungs = application.GetResult('TDLeftAndRightLungs');
            fissure_plane = application.GetResult('TDFissurePlane');
            lung_mask = application.GetResult('TDLeftAndRightLungs');
            left_lung_template = application.GetTemplateImage(TDContext.LeftLungROI);
            right_lung_template = application.GetTemplateImage(TDContext.RightLungROI);
            results_left = TDLobesFromFissurePlane.GetLeftLungResults(left_lung_template, lung_mask.Copy, fissure_plane.Copy);
            results_right = TDLobesFromFissurePlane.GetRightLungResults(right_lung_template, lung_mask, fissure_plane);
            
            results = TDCombineLeftAndRightImages(application.GetTemplateImage(TDContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = TDImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        function left_results = GetLeftLungResults(lung_template, lung_mask, fissure_plane)

            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == 2));
            
            lung_mask.ResizeToMatch(lung_template);
            
            
            fissure_plane.ResizeToMatch(lung_template);
            fissure_plane = find(fissure_plane.RawImage(:) == 4);
            
            results_left_raw = TDGetLobesFromFissurePoints(fissure_plane, lung_mask, lung_template.ImageSize);

            results_left_raw(results_left_raw == 2) = 5;
            results_left_raw(results_left_raw == 3) = 6;
            
            left_results = lung_template.BlankCopy;
            left_results.ChangeRawImage(results_left_raw);
        end
        
        function right_results = GetRightLungResults(lung_template, lung_mask, fissure_plane)
            
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == 1));
            
            lung_mask.ResizeToMatch(lung_template);
            fissure_plane.ResizeToMatch(lung_template);
            fissure_plane_o = find(fissure_plane.RawImage(:) == 3);
            
            results_right_raw = TDGetLobesFromFissurePoints(fissure_plane_o, lung_mask, lung_template.ImageSize);
            
            % Mid lobe
            fissure_plane_m = find(fissure_plane.RawImage(:) == 2);
            lung_mask_excluding_lower = lung_mask.Copy;
            lung_mask_excluding_lower.ChangeRawImage(results_right_raw == 2);
            results_mid_right_raw = TDGetLobesFromFissurePoints(fissure_plane_m, lung_mask_excluding_lower, lung_template.ImageSize);
            
            
            results_right_raw(results_right_raw == 3) = 4;
            results_right_raw(results_mid_right_raw == 2) = 1;
            results_right_raw(results_mid_right_raw == 3) = 2;
                        
            right_results = lung_template.BlankCopy;
            right_results.ChangeRawImage(results_right_raw);
        end
    end
end