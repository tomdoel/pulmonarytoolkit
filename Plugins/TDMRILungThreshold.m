classdef TDMRILungThreshold < TDPlugin
    % TDMRILungThreshold. Plugin for segmenting the lungs from MRI data
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'MRI Lungs'
        ToolTip = 'Shows a segmentation of the airways illustrating deleted points'
        Category = 'Lungs'

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
        function results = RunPlugin(dataset, reporting)
            if dataset.IsGasMRI
                full_image = dataset.GetResult('TDInvertImage');
                [lung_mask, bounds] = TDComputeSegmentLungsMRI(full_image, 2, reporting);
                lung_mask.CropToFit;
                lung_mask.ImageType = TDImageType.Colormap;
                results.Bounds = bounds;
                results.LungMask = lung_mask;
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                full_image = dataset.GetResult('TDOriginalImage');
                [lung_mask, bounds] = TDComputeSegmentLungsMRI(full_image, 1, reporting);
                lung_mask.CropToFit;
                lung_mask.ImageType = TDImageType.Colormap;
                results.Bounds = bounds;
                results.LungMask = lung_mask;
            else
                reporting.Error;
            end
        end
        
        function results = GenerateImageFromResults(threshold_results, image_templates, reporting)
            results = threshold_results.LungMask;
        end        
    end
end

