classdef TDFissurePlane < TDPlugin
    % TDFissurePlane. Plugin to obtain an approximation of the fissures
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     This is an intermediate stage towards lobar segmentation.
    %
    %     TDFissureApproximation uses the approximate lobar segmentation
    %     generated using TDLobesByVesselnessDensityUsingWatershed. The fissures
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
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(application, reporting)
            
            left_and_right_lungs = application.GetResult('TDLeftAndRightLungs');
            
            
            results_left = TDFissurePlane.GetLeftLungResults(application, reporting);
            results_right = TDFissurePlane.GetRightLungResults(application, reporting);
            
            results = TDCombineLeftAndRightImages(application.GetTemplateImage(TDContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = TDImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        function left_results = GetLeftLungResults(application, reporting)
            max_fissure_points = application.GetResult('TDMaximumFissurePoints');
            
            
            left_lung_roi = application.GetResult('TDGetLeftLungROI');
            max_fissure_points.ResizeToMatch(left_lung_roi);
            max_fissure_points = find(max_fissure_points.RawImage(:) == 1);

            if isempty(max_fissure_points)
                reporting.Error('TDFissurePlane:NoLeftObliqueFissure', 'Unable to find the left oblique fissure');
            end
            
            results_left_raw = TDGetFissurePlane(max_fissure_points, left_lung_roi.ImageSize, 3);
                        
            left_results = left_lung_roi.BlankCopy;
            left_results.ChangeRawImage(4*uint8(results_left_raw == 1));
        end
        
        function right_results = GetRightLungResults(application, reporting)
            max_fissure_points = application.GetResult('TDMaximumFissurePoints');
            
            right_lung_roi = application.GetResult('TDGetRightLungROI');
            max_fissure_points.ResizeToMatch(right_lung_roi);
            max_fissure_points_o = find(max_fissure_points.RawImage(:) == 1);
            max_fissure_points_m = find(max_fissure_points.RawImage(:) == 8);
            
            if isempty(max_fissure_points_o)
                reporting.Error('TDFissurePlane:NoRightObliqueFissure', 'Unable to find the right oblique fissure');
            end
            
            if isempty(max_fissure_points_m)
                reporting.ShowWarning('TDFissurePlane:NoRightHoritontalFissure', 'Unable to find the right horizontal fissure', []);
            end
            
            results_right_raw = 3*TDGetFissurePlane(max_fissure_points_o, right_lung_roi.ImageSize, 3);
            
            right_lung_mask = application.GetResult('TDLeftAndRightLungs');
            right_lung_mask.ResizeToMatch(right_lung_roi);
            right_lung_mask.ChangeRawImage(right_lung_mask.RawImage == 1);
            
            fissure_plane_oblique = find(results_right_raw == 3);
            
            % Create a mask which excludes the lower lobe
            lobes_right_raw = TDGetLobesFromFissurePoints(fissure_plane_oblique, right_lung_mask, right_lung_roi.ImageSize);
            right_lung_mask.ChangeRawImage(lobes_right_raw == 2); 
            
            
            % The final value controls the extrapolation. 4 is a reasonable 
            % value, but higher values may be needed if few fissure points have 
            % been found, especially for the right mid fissure.
            if ~isempty(max_fissure_points_m)
                results_right_m_raw = TDGetFissurePlane(max_fissure_points_m, right_lung_roi.ImageSize, 4);
                results_right_m_raw(right_lung_mask.RawImage == 0) = 0;
                results_right_raw(results_right_m_raw == 1) = 2;
            end
            
            
            right_results = right_lung_roi.BlankCopy;
            right_results.ChangeRawImage(results_right_raw);
        end
    end
end