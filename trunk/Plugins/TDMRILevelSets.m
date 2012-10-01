classdef TDMRILevelSets < TDPlugin
    % TDMRILevelSets. Plugin for segmenting the lungs from MRI data
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDMRILevelSets computes a segmentation of the lungs using a level set
    %     method
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'MRI Lungs <br>Level Sets'
        ToolTip = 'Segment lungs from MRI images using level sets'
        Category = 'Lungs'
        
        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            left_and_right_lungs_initial = dataset.GetResult('TDMRILevelSetsInitialiser');
            roi = dataset.GetResult('TDLungROI');
            left_roi = TDGetLeftLungROIFromLeftAndRightLungs(roi, left_and_right_lungs_initial, reporting);
            right_roi = TDGetRightLungROIFromLeftAndRightLungs(roi, left_and_right_lungs_initial, reporting);
            results = dataset.GetTemplateImage(TDContext.LungROI);
            results_left = TDMRILevelSets.ProcessLevelSets(dataset, left_roi, left_and_right_lungs_initial, 2, reporting);
            results_right = TDMRILevelSets.ProcessLevelSets(dataset, right_roi, left_and_right_lungs_initial, 1, reporting);

            results_right.ResizeToMatch(results);
            results_left.ResizeToMatch(results);
            results_raw = uint8(results_right.RawImage);
            results_raw(results_left.RawImage) = 2;
            results.ChangeRawImage(results_raw);
            results.ImageType = TDImageType.Colormap;
        end
        
        function results = ProcessLevelSets(dataset, lung_roi, left_and_right_lungs_initial, mask_colour, reporting)
            lung_mask = left_and_right_lungs_initial.Copy;
            lung_mask.ResizeToMatch(lung_roi);
            lung_mask.ChangeRawImage(lung_mask.RawImage == mask_colour);

            threshold = dataset.GetResult('TDMRILungThreshold');

            results = TDMRILevelSets.SolveLevelSetsByCoronalSlice(lung_roi, lung_mask, threshold.Bounds, reporting);
            
            results.ImageType = TDImageType.Colormap;
        end
        
        function results = SolveLevelSetsByCoronalSlice(lung_roi, lung_mask, bounds, reporting)
            figure_handle = figure;
            results = lung_mask.Copy;
            results.ImageType = TDImageType.Colormap;
            for coronal_index = 1 : lung_roi.ImageSize(1)
                lung_roi_slice = TDImage(lung_roi.GetSlice(coronal_index, TDImageOrientation.Coronal));
                lung_mask_slice = TDImage(lung_mask.GetSlice(coronal_index, TDImageOrientation.Coronal));
                if any(lung_mask_slice.RawImage(:))
                    results_slice = TDLevelSets2D(lung_roi_slice, lung_mask_slice, bounds, figure_handle, reporting);
                else
                    results_slice = lung_mask_slice;
                end
                results.ReplaceImageSlice(results_slice.RawImage, coronal_index, TDImageOrientation.Coronal);
            end
        end
    end
end