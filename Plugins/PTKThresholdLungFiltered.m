classdef PTKThresholdLungFiltered < PTKPlugin
    % PTKThresholdLungFiltered. Plugin to detect airlike voxels using thresholding.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKThresholdLungFiltered uses the library routine PTKThresholdAirway to
    %     detect air-like voxels in the lung. Before thresholding, a Gaussian
    %     filter is applied to the image.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Lung threshold <br>(filtered)'
        ToolTip = 'Detect air-like voxels in the lung through thresholding'
        Category = 'Lungs'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function threshold_image = RunPlugin(dataset, ~)
            if dataset.IsGasMRI
                lung_roi = dataset.GetResult('PTKInvertImage');
                filtered_image = PTKGaussianFilter(lung_roi, 2);
            else
                lung_roi = dataset.GetResult('PTKLungROI');
                filtered_image = PTKGaussianFilter(lung_roi, 0.5);
            end
            
            if dataset.IsGasMRI
                mri_lung_threshold = dataset.GetResult('PTKMRILungThreshold');
                limits = mri_lung_threshold.Bounds;
                raw_image = filtered_image.RawImage;
                raw_image = (raw_image >= limits(1) & raw_image <= limits(2));
                threshold_image = lung_roi.BlankCopy;
                threshold_image.ChangeRawImage(raw_image);
                threshold_image.ImageType = PTKImageType.Colormap;
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                mri_lung_threshold = dataset.GetResult('PTKMRILungThreshold');
                limits = mri_lung_threshold.Bounds;
                raw_image = filtered_image.RawImage;
                raw_image = (raw_image >= limits(1) & raw_image <= limits(2));
                threshold_image = lung_roi.BlankCopy;
                threshold_image.ChangeRawImage(raw_image);
                threshold_image.ImageType = PTKImageType.Colormap;
            else
                limit_1 = lung_roi.RescaledToGreyscale(-1024);
                limit_2 = lung_roi.RescaledToGreyscale(-775);
                limit_3 = lung_roi.RescaledToGreyscale(-400);
                
                % Voxles within the wider filtered threshold are given value 2
                filtered_image = uint8(2*(filtered_image.RawImage >= limit_1 & filtered_image.RawImage <= limit_3));
                
                % Voxles within the narrow unfiltered threshold are given value 1
                filtered_image(lung_roi.RawImage >= limit_1 & lung_roi.RawImage <= limit_2) = 1;
                
                threshold_image = lung_roi.BlankCopy;
                threshold_image.ChangeRawImage(filtered_image);
                
                threshold_image.ImageType = PTKImageType.Colormap;
            end
        end
    end
end