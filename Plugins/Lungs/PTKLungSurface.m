classdef PTKLungSurface < PTKPlugin
    % PTKLungSurface. Plugin for finding points around the surface of the lungs
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKLungSurface runs the library function PTKGetSurfaceFromSegmentation
    %     to find the lung surface and returns this as an image.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Lung Surface'
        ToolTip = 'Segment the lung surface'
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
            lung_mask = dataset.GetResult('PTKLeftAndRightLungs');
            results = lung_mask.BlankCopy;
            lungs = PTKGetSurfaceFromSegmentation(uint8(lung_mask.RawImage > 0));
            results.ChangeRawImage(lungs);
            results.ImageType = PTKImageType.Colormap;
        end
    end
end