classdef PTKFissurePlaneHorizontal < PTKPlugin
    % PTKFissurePlaneHorizontal. Plugin to obtain an approximation of the fissures
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
        ButtonText = 'Fissure Plane<br>horizontal'
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
            left_and_right_lungs = application.GetResult('PTKLeftAndRightLungs');
            max_fissure_points = application.GetResult('PTKMaximumFissurePointsHorizontal');            
            right_upper_lung = application.GetResult('PTKLobesFromFissurePlaneOblique');
            right_upper_lung.ChangeRawImage(right_upper_lung.RawImage == 1);
            
            results = PTKFissurePlaneHorizontal.GetRightLungResults(max_fissure_points, right_upper_lung, application.GetResult('PTKGetRightLungROI'), reporting);
            if ~isempty(results)
                results.ResizeToMatch(left_and_right_lungs);
            else
                results = application.GetResult('PTKFissurePlaneOblique');
            end
            results.ImageType = PTKImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        
        function right_results = GetRightLungResults(max_fissure_points, lung_mask, right_lung_roi, reporting)
            max_fissure_points.ResizeToMatch(right_lung_roi);
            lung_mask.ResizeToMatch(right_lung_roi);
            
            max_fissure_points_m = find(max_fissure_points.RawImage(:) == 8);
            
            if isempty(max_fissure_points_m)
                reporting.ShowWarning('PTKFissurePlane:NoRightHoritontalFissure', 'Unable to find the right horizontal fissure', []);
            end
            
            if ~isempty(max_fissure_points_m)
                [~, fissure_plane] = PTKSeparateIntoLobesWithVariableExtrapolation(max_fissure_points_m, lung_mask, right_lung_roi.ImageSize, 20, reporting);
                fissure_plane(lung_mask.RawImage == 0) = 0;
                fissures_right = 2*uint8(fissure_plane == 3);
            else
                right_results = [];
                return;
            end
            
            right_results = right_lung_roi.BlankCopy;
            right_results.ChangeRawImage(fissures_right);
        end
        
    end
end