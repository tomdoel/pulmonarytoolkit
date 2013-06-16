classdef PTKFissurePlane < PTKPlugin
    % PTKFissurePlane. Plugin to obtain an approximation of the fissures
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     This is an intermediate stage towards lobar segmentation.
    %
    %     PTKFissureApproximation uses the approximate lobar segmentation
    %     generated using PTKLobesByVesselnessDensityUsingWatershed. The fissures
    %     are the watershed boundaries within the lung.
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
        ButtonText = 'Fissure Plane'
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
            
            
            results_left = PTKFissurePlane.GetLeftLungResults(application, reporting);
            results_right = PTKFissurePlane.GetRightLungResults(application, reporting);
            
            results = PTKCombineLeftAndRightImages(application.GetTemplateImage(PTKContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = PTKImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        function left_results = GetLeftLungResults(application, reporting)
            max_fissure_points = application.GetResult('PTKMaximumFissurePoints');
            
            
            left_lung_roi = application.GetResult('PTKGetLeftLungROI');
            max_fissure_points.ResizeToMatch(left_lung_roi);
            max_fissure_points = find(max_fissure_points.RawImage(:) == 1);

            if isempty(max_fissure_points)
                reporting.Error('PTKFissurePlane:NoLeftObliqueFissure', 'Unable to find the left oblique fissure');
            end
            
            results_left_raw = PTKGetFissurePlane(max_fissure_points, left_lung_roi.ImageSize, 3);
                        
            left_results = left_lung_roi.BlankCopy;
            left_results.ChangeRawImage(4*uint8(results_left_raw == 1));
        end
        
        function right_results = GetRightLungResults(application, reporting)
            max_fissure_points = application.GetResult('PTKMaximumFissurePoints');
            
            right_lung_roi = application.GetResult('PTKGetRightLungROI');
            max_fissure_points.ResizeToMatch(right_lung_roi);
            max_fissure_points_o = find(max_fissure_points.RawImage(:) == 1);
            max_fissure_points_m = find(max_fissure_points.RawImage(:) == 8);
            
            if isempty(max_fissure_points_o)
                reporting.Error('PTKFissurePlane:NoRightObliqueFissure', 'Unable to find the right oblique fissure');
            end
            
            if isempty(max_fissure_points_m)
                reporting.ShowWarning('PTKFissurePlane:NoRightHoritontalFissure', 'Unable to find the right horizontal fissure', []);
            end
            
            extrapolation = 3;
            
            results_right_raw = 3*PTKGetFissurePlane(max_fissure_points_o, right_lung_roi.ImageSize, extrapolation);
            
            right_lung_mask = application.GetResult('PTKLeftAndRightLungs');
            right_lung_mask.ResizeToMatch(right_lung_roi);
            right_lung_mask.ChangeRawImage(right_lung_mask.RawImage == 1);
            
            fissure_plane_oblique = find(results_right_raw == 3);
            
            % Create a mask which excludes the lower lobe
            lobes_right_raw = PTKGetLobesFromFissurePoints(fissure_plane_oblique, right_lung_mask, reporting);
            right_lung_mask.ChangeRawImage(lobes_right_raw.RawImage == 1);
            
            % The final value controls the extrapolation. 4 is a reasonable 
            % value, but higher values may be needed if few fissure points have 
            % been found, especially for the right mid fissure.
            if ~isempty(max_fissure_points_m)
                extrapolation = 10; % A value of 4 typically works well, but may need to be increased in some cases
                results_right_m_raw = PTKGetFissurePlane(max_fissure_points_m, right_lung_roi.ImageSize, extrapolation);
                results_right_m_raw(right_lung_mask.RawImage == 0) = 0;
                results_right_raw(results_right_m_raw == 1) = 2;
            end
            
            
            right_results = right_lung_roi.BlankCopy;
            right_results.ChangeRawImage(results_right_raw);
        end
    end
end