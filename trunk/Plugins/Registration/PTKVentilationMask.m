classdef PTKVentilationMask < PTKPlugin
    % PTKVentilationMask. Plugin for segmenting ventilation values from
    %     hyperpolarised gas MRI
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
        ButtonText = 'Ventilation <BR>Mask'
        ToolTip = ''
        Category = 'Lungs'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            original_image = dataset.GetResult('PTKOriginalImage');
            noise_roi = original_image.RawImage(1, 20:220, 10:60); % Kaushik et al
            roi = dataset.GetResult('PTKLungROI');
            std_noise = std(double(noise_roi(:)));
            mean_signal = mean(double(noise_roi(:)));
            threshold = mean_signal + 2*std_noise;
            
            threshold_image = logical(roi.RawImage >= threshold);
            results = roi.BlankCopy;
            results.ChangeRawImage(threshold_image);
            
            results.BinaryMorph(@imopen, 6);
            
            results.ChangeRawImage(3*uint8(results.RawImage));
            
            results.ImageType = PTKImageType.Colormap;
        end
    end
end
