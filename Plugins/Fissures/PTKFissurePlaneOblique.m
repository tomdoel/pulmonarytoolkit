classdef PTKFissurePlaneOblique < PTKPlugin
    % PTKFissurePlaneOblique. Plugin to obtain an approximation of the fissures
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
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Fissure Plane<br>Oblique'
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
            
            max_fissure_points = application.GetResult('PTKMaximumFissurePointsOblique');
            left_and_right_lungs = application.GetResult('PTKLeftAndRightLungs');
            
            results_left = PTKFissurePlaneOblique.GetLeftLungResults(max_fissure_points, application.GetResult('PTKGetLeftLungROI'), left_and_right_lungs, reporting);
            results_right = PTKFissurePlaneOblique.GetRightLungResults(max_fissure_points, application.GetResult('PTKGetRightLungROI'), left_and_right_lungs, reporting);
            
            results = PTKCombineLeftAndRightImages(application.GetTemplateImage(PTKContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = PTKImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        
        function results = GetLeftLungResults(max_fissure_points, lung_roi, left_and_right_lungs, reporting)
            max_fissure_points = max_fissure_points.Copy;
            
            lung_mask = left_and_right_lungs.Copy;
            lung_mask.ResizeToMatch(lung_roi);
            lung_mask.ChangeRawImage(lung_mask.RawImage == 2);
            
            max_fissure_points.ResizeToMatch(lung_roi);
            max_fissure_points = find(max_fissure_points.RawImage(:) == 1);

            if isempty(max_fissure_points)
                reporting.Error('PTKFissurePlane:NoLeftObliqueFissure', 'Unable to find the left oblique fissure');
            end
            
            [~, fissure_plane] = PTKSeparateIntoLobesWithVariableExtrapolation(max_fissure_points, lung_mask, lung_roi.ImageSize, 5, reporting);
                        
            results = lung_roi.BlankCopy;
            results.ChangeRawImage(4*uint8(fissure_plane == 3));
        end
        
        function results = GetRightLungResults(max_fissure_points, lung_roi, left_and_right_lungs, reporting)
            max_fissure_points = max_fissure_points.Copy;
            
            lung_mask = left_and_right_lungs.Copy;
            lung_mask.ResizeToMatch(lung_roi);
            lung_mask.ChangeRawImage(lung_mask.RawImage == 1);
            
            max_fissure_points.ResizeToMatch(lung_roi);
            max_fissure_points = find(max_fissure_points.RawImage(:) == 1);
            
            if isempty(max_fissure_points)
                reporting.Error('PTKFissurePlane:NoRightObliqueFissure', 'Unable to find the right oblique fissure');
            end
            
            [~, fissure_plane] = PTKSeparateIntoLobesWithVariableExtrapolation(max_fissure_points, lung_mask, lung_roi.ImageSize, 5, reporting);
            
            results = lung_roi.BlankCopy;
            results.ChangeRawImage(fissure_plane);
        end
        
    end
end