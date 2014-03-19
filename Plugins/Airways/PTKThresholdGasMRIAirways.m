classdef PTKThresholdGasMRIAirways < PTKPlugin
    % PTKThresholdGasMRIAirways. Plugin for segmenting the lungs from gas MRI data.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
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
        ButtonText = 'Gas Airways'
        ToolTip = 'Shows a segmentation of the airways by thresholding'
        Category = 'Airways'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            results = dataset.GetResult('PTKOriginalImage');
            results_filtered = PTKGaussianFilter(results, 2);
            results_filtered.ChangeRawImage(results_filtered.RawImage > 50);
            results.ChangeRawImage(results.RawImage > 100);
            extended = results.Copy;
            extended_raw = extended.RawImage;
            extended_raw = imdilate(extended_raw, ones(3,1,1));
            extended.BinaryMorph(@imdilate, 15);
            extended.ChangeRawImage(extended.RawImage | extended_raw);
            extended.ChangeRawImage(extended.RawImage & results_filtered.RawImage);
            results.ChangeRawImage(results.RawImage | extended.RawImage);
            results.ImageType = PTKImageType.Colormap;
       end
    end
end