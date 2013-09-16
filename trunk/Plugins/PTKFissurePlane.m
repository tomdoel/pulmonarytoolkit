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
            left_lung_mask = application.GetResult('PTKLeftAndRightLungs');
            left_lung_mask.ResizeToMatch(left_lung_roi);
            left_lung_mask.ChangeRawImage(left_lung_mask.RawImage == 2);
            
            max_fissure_points.ResizeToMatch(left_lung_roi);
            max_fissure_points = find(max_fissure_points.RawImage(:) == 1);

            if isempty(max_fissure_points)
                reporting.Error('PTKFissurePlane:NoLeftObliqueFissure', 'Unable to find the left oblique fissure');
            end
            
            [lobes_raw, fissure_plane] = PTKFissurePlane.SeparateIntoLobesWithVariableExtrapolation(max_fissure_points, left_lung_mask, left_lung_roi.ImageSize, 5, reporting);
            
            results_left_raw = fissure_plane;
            
            left_results = left_lung_roi.BlankCopy;
            left_results.ChangeRawImage(4*uint8(results_left_raw == 3));
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
            
            right_lung_mask = application.GetResult('PTKLeftAndRightLungs');
            right_lung_mask.ResizeToMatch(right_lung_roi);
            right_lung_mask.ChangeRawImage(right_lung_mask.RawImage == 1);
            
            [lobes_right, fissures_right] = PTKFissurePlane.SeparateIntoLobesWithVariableExtrapolation(max_fissure_points_o, right_lung_mask, right_lung_roi.ImageSize, 5, reporting);
            right_lung_mask.ChangeRawImage(lobes_right.RawImage == 1);
            
            
            % The final value controls the extrapolation. 4 is a reasonable 
            % value, but higher values may be needed if few fissure points have 
            % been found, especially for the right mid fissure.
            if ~isempty(max_fissure_points_m)
                [~, fissure_plane] = PTKFissurePlane.SeparateIntoLobesWithVariableExtrapolation(max_fissure_points_m, right_lung_mask, right_lung_roi.ImageSize, 20, reporting);
                results_right_m_raw = fissure_plane;
                results_right_m_raw(right_lung_mask.RawImage == 0) = 0;
                fissures_right(results_right_m_raw == 3) = 2;
            end
            
            
            right_results = right_lung_roi.BlankCopy;
            right_results.ChangeRawImage(fissures_right);
        end
        
        function [lobes_raw, fissure_plane] = SeparateIntoLobesWithVariableExtrapolation(max_fissure_points, lung_mask, image_size, volume_fraction_threshold, reporting)
            start_extrapolation = 4;
            max_extrapolation = 20;
            
            extrapolation = start_extrapolation;
            
            compute_again = true;
            
            while compute_again
                fissure_plane = 3*PTKGetFissurePlane(max_fissure_points, image_size, extrapolation);
                fissure_plane_indices = find(fissure_plane == 3);
                
                % Create a mask which excludes the lower lobe
                lobes_raw = PTKGetLobesFromFissurePoints(fissure_plane_indices, lung_mask, volume_fraction_threshold, reporting);
                
                % If the lobe separation fails, then try a larger extrapolation
                if isempty(lobes_raw)
                    extrapolation = extrapolation + 2;
                    if extrapolation > max_extrapolation
                        reporting.Error('PTKFissurePlane:UnableToDivide', 'Could not separate the lobes');
                    end
                    compute_again = true;
                else
                    compute_again = false;
                    disp(['Final extrapolation:' int2str(extrapolation)]);
                end
            end
        end
    end
end