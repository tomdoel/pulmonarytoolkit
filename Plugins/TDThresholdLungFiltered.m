classdef TDThresholdLungFiltered < TDPlugin
    % TDThresholdLungFiltered. Plugin to detect airlike voxels using thresholding.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDThresholdLungFiltered uses the library routine TDThresholdAirway to
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
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function threshold_image = RunPlugin(dataset, ~)
            lung_image = dataset.GetResult('TDLungROI');
            
            if ~lung_image.IsCT
                error('Unsupported modality');
            end
            limit_1 = lung_image.RescaledToGreyscale(-1024);
            limit_2 = lung_image.RescaledToGreyscale(-775);
            limit_3 = lung_image.RescaledToGreyscale(-400);
            
            filtered_image = TDGaussianFilter(lung_image, 0.5);
            
            % Voxles within the wider filtered threshold are given value 2
            filtered_image = uint8(2*(filtered_image.RawImage >= limit_1 & filtered_image.RawImage <= limit_3));
            
            % Voxles within the narrow unfiltered threshold are given value 1
            filtered_image(lung_image.RawImage >= limit_1 & lung_image.RawImage <= limit_2) = 1;
            
            threshold_image = lung_image.BlankCopy;
            threshold_image.ChangeRawImage(filtered_image);
            
            threshold_image.ImageType = TDImageType.Colormap;
        end
    end
end