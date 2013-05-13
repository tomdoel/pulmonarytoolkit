classdef PTKLobesFromFissurePlane < PTKPlugin
    % PTKLobesFromFissurePlane. Plugin which is part of the lobar segmentation.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKLobesFromFissurePlane is an intermediate stage in segmenting the
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
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(application, reporting)
            
            left_and_right_lungs = application.GetResult('PTKLeftAndRightLungs');
            fissure_plane = application.GetResult('PTKFissurePlane');
            lung_mask = application.GetResult('PTKLeftAndRightLungs');
            left_lung_template = application.GetTemplateImage(PTKContext.LeftLung).BlankCopy;
            right_lung_template = application.GetTemplateImage(PTKContext.RightLung).BlankCopy;
            results_left = PTKLobesFromFissurePlane.GetLeftLungResults(left_lung_template, lung_mask.Copy, fissure_plane.Copy, reporting);
            results_right = PTKLobesFromFissurePlane.GetRightLungResults(right_lung_template, lung_mask, fissure_plane, reporting);
            
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
            
            results_left_raw = PTKGetLobesFromFissurePoints(fissure_plane, lung_mask, lung_template.ImageSize);

            results_left_raw(results_left_raw == 2) = 5;
            results_left_raw(results_left_raw == 3) = 6;
            
            left_results = lung_template.BlankCopy;
            left_results.ChangeRawImage(results_left_raw);
        end
        
        function right_results = GetRightLungResults(lung_template, lung_mask, fissure_plane, reporting)
            
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage == 1));
            
            lung_mask.ResizeToMatch(lung_template);
            fissure_plane.ResizeToMatch(lung_template);
            fissure_plane_o = find(fissure_plane.RawImage(:) == 3);
            
            results_right_raw = PTKGetLobesFromFissurePoints(fissure_plane_o, lung_mask, lung_template.ImageSize);
            
            % Mid lobe
            fissure_plane_m = find(fissure_plane.RawImage(:) == 2);
            
            if ~isempty(fissure_plane_m)
                lung_mask_excluding_lower = lung_mask.Copy;
                lung_mask_excluding_lower.ChangeRawImage(results_right_raw == 2);
                results_mid_right_raw = PTKGetLobesFromFissurePoints(fissure_plane_m, lung_mask_excluding_lower, lung_template.ImageSize);

                results_right_raw(results_right_raw == 3) = 4;
                results_right_raw(results_mid_right_raw == 2) = 1;
                results_right_raw(results_mid_right_raw == 3) = 2;
            else
                reporting.ShowWarning('PTKLobesFromFissurePlane:NoRightObliqueFissure', 'Unable to find the right horizontal fissure. No middle right lobe segmentation will be shown.', []);
                results_right_raw(results_right_raw == 2) = 1;
                results_right_raw(results_right_raw == 3) = 4;
            end
            
                        
            right_results = lung_template.BlankCopy;
            right_results.ChangeRawImage(results_right_raw);
        end
    end
end