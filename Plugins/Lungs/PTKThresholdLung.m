classdef PTKThresholdLung < PTKPlugin
    % PTKThresholdLung. Plugin to detect airlike voxels using thresholding.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKThresholdLung uses the library routine PTKThresholdAirway to detect
    %     air-like voxels in the lung.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Lung Threshold'
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
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, ~)
            if dataset.IsGasMRI
                results = dataset.GetResult('PTKSegmentGasMRI');
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                lung_threshold = dataset.GetResult('PTKMRILungThreshold');
                limits = lung_threshold.Bounds;
                lung_roi = dataset.GetResult('PTKLungROI');
                raw_image = lung_roi.RawImage;
                raw_image = (raw_image >= limits(1) & raw_image <= limits(2));
                results = lung_roi.BlankCopy;
                results.ChangeRawImage(raw_image);
                results.ImageType = PTKImageType.Colormap;
            else
                results = dataset.GetResult('PTKLungROI');
                results = PTKThresholdAirway(results);
                results.ImageType = PTKImageType.Colormap;
            end
        end
    end
end