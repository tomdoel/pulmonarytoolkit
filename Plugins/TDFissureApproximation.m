classdef TDFissureApproximation < TDPlugin
    % TDFissureApproximation. Plugin to obtain an approximation of the fissures
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
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    

    properties
        ButtonText = 'Fissure Plane<br>Initial guess'
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
            
            lobes_guess = application.GetResult('TDLobesByVesselnessDensityUsingWatershed');
            
            left_and_right_lungs = application.GetResult('TDLeftAndRightLungs');
            
            results_left = TDFissureApproximation.GetLeftLungResults(application, lobes_guess, left_and_right_lungs);
            results_right = TDFissureApproximation.GetRightLungResults(application, lobes_guess, left_and_right_lungs);
            
            results = TDCombineLeftAndRightImages(application.GetTemplateImage(TDContext.LungROI), results_left, results_right, left_and_right_lungs);
            results.ImageType = TDImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end    
    
    methods (Static, Access = private)
        function left_results = GetLeftLungResults(application, lobes_guess, left_and_right_lungs)
            left_lung_roi = application.GetResult('TDGetLeftLungROI');
            
            lobes_guess = lobes_guess.Copy;
            lobes_guess.ResizeToMatch(left_lung_roi);
            left_and_right_lungs = left_and_right_lungs.Copy;
            left_and_right_lungs.ResizeToMatch(left_lung_roi);
            
            fissures = (lobes_guess.RawImage == 0) & (left_and_right_lungs.RawImage == 2);
            left_results = left_lung_roi.BlankCopy;
            left_results.ChangeRawImage(6*uint8(fissures));
        end
        
        function right_results = GetRightLungResults(application, lobes_guess, left_and_right_lungs)
            right_lung_roi = application.GetResult('TDGetRightLungROI');
            lobes_guess = lobes_guess.Copy;
            lobes_guess.ResizeToMatch(right_lung_roi);
            left_and_right_lungs = left_and_right_lungs.Copy;
            left_and_right_lungs.ResizeToMatch(right_lung_roi);

            fissures = (lobes_guess.RawImage == 0) & (left_and_right_lungs.RawImage == 1);
            
            RMU = (lobes_guess.RawImage == 1) | (lobes_guess.RawImage == 2);
            filter = zeros(3,3,3, 'uint8');
            filter(5) = true; filter(11) = true; filter(13) = true; filter(15) = true; filter(17) = true; filter(23) = true;
            border_RMU = convn(RMU, filter, 'same');

            RL = (lobes_guess.RawImage == 4);
            border_RL = convn(RL, filter, 'same');

            % Oblique fissure
            R_fissure = uint8(border_RL & border_RMU & fissures);
            
            RU = lobes_guess.RawImage == 1;
            RM = lobes_guess.RawImage == 2;
            border_RU = convn(RU, filter, 'same');
            border_RM = convn(RM, filter, 'same');
            RM_fissure = uint8(border_RM & border_RU & fissures);
            
            right_results = right_lung_roi.BlankCopy;
            right_results.ChangeRawImage(2*uint8(R_fissure) + 3*uint8(RM_fissure));
        end
    end
end