classdef PTKSegmentGasMRI < PTKPlugin
    % PTKSegmentGasMRI. Plugin for segmenting the lungs from gas MRI data.
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
        ButtonText = 'Gas Lungs'
        ToolTip = ''
        Category = 'Lungs'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '2'
        Context = PTKContextSet.OriginalImage
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            results = dataset.GetResult('PTKOriginalImage', PTKContext.OriginalImage);
            results = PTKGaussianFilter(results, 2);
            results.ChangeRawImage(results.RawImage > 15);
            results.ImageType = PTKImageType.Colormap;
       end
    end
end