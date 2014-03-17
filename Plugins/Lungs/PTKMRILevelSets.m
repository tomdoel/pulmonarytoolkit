classdef PTKMRILevelSets < PTKPlugin
    % PTKMRILevelSets. Plugin for segmenting the lungs from MRI data
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKMRILevelSets computes a segmentation of the lungs using a level set
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
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            left_and_right_lungs_initial = dataset.GetResult('PTKMRILevelSetsInitialiser');
            roi = dataset.GetResult('PTKLungROI');
            left_roi = PTKGetLeftLungROIFromLeftAndRightLungs(roi, left_and_right_lungs_initial, reporting);
            right_roi = PTKGetRightLungROIFromLeftAndRightLungs(roi, left_and_right_lungs_initial, reporting);
            results = dataset.GetTemplateImage(PTKContext.LungROI);
            results_left = PTKMRILevelSets.ProcessLevelSets(dataset, left_roi, left_and_right_lungs_initial, 2, reporting);
            results_right = PTKMRILevelSets.ProcessLevelSets(dataset, right_roi, left_and_right_lungs_initial, 1, reporting);

            results_right.ResizeToMatch(results);
            results_left.ResizeToMatch(results);
            results_raw = uint8(results_right.RawImage);
            results_raw(results_left.RawImage) = 2;
            results.ChangeRawImage(results_raw);
            results.ImageType = PTKImageType.Colormap;
        end
        
        function results = ProcessLevelSets(dataset, lung_roi, left_and_right_lungs_initial, mask_colour, reporting)
            lung_mask = left_and_right_lungs_initial.Copy;
            lung_mask.ResizeToMatch(lung_roi);
            lung_mask.ChangeRawImage(lung_mask.RawImage == mask_colour);

            threshold = dataset.GetResult('PTKMRILungThreshold');

            results = PTKMRILevelSets.SolveLevelSetsByCoronalSlice(lung_roi, lung_mask, threshold.Bounds, reporting);
            
            results.ImageType = PTKImageType.Colormap;
        end
        
        function results = SolveLevelSetsByCoronalSlice(lung_roi, lung_mask, bounds, reporting)
            if PTKSoftwareInfo.GraphicalDebugMode
                figure_handle = figure;
            else
                figure_handle = [];
            end
            
            results = lung_mask.Copy;
            results.ImageType = PTKImageType.Colormap;
            for coronal_index = 1 : lung_roi.ImageSize(1)
                lung_roi_slice = PTKImage(lung_roi.GetSlice(coronal_index, PTKImageOrientation.Coronal));
                lung_mask_slice = PTKImage(lung_mask.GetSlice(coronal_index, PTKImageOrientation.Coronal));
                if any(lung_mask_slice.RawImage(:))
                    results_slice = PTKLevelSets2D(lung_roi_slice, lung_mask_slice, bounds, figure_handle, reporting);
                else
                    results_slice = lung_mask_slice;
                end
                results.ReplaceImageSlice(results_slice.RawImage, coronal_index, PTKImageOrientation.Coronal);
            end
            
            results.BinaryMorph(@imopen, 2);
            
            % Select largest component in each coronal slice
            for coronal_index = 1 : results.ImageSize(1)
                lung_mask_slice = results.GetSlice(coronal_index, PTKImageOrientation.Coronal);
                if any(lung_mask_slice(:))

                    % Obtain connected component matrix
                    cc = bwconncomp(lung_mask_slice, 8);
                    
                    % Find largest region
                    num_pixels = cellfun(@numel, cc.PixelIdxList);
                    [~, sorted_largest_areas_indices] = sort(num_pixels, 'descend');
                    largest_region_index = sorted_largest_areas_indices(1);
                    lung_mask_slice = results_slice.RawImage;
                    lung_mask_slice(:) = false;
                    lung_mask_slice(cc.PixelIdxList{largest_region_index}) = true;
                    
                    results.ReplaceImageSlice(lung_mask_slice, coronal_index, PTKImageOrientation.Coronal);
                end
            end
        end
    end
end