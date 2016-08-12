classdef PTKThresholdLungInterior < PTKPlugin
    % PTKThresholdLungInterior. Plugin to detect airlike voxels using thresholding.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKThresholdLungInterior finds interior lung and airway spaces.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Lung Interior'
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
        
        EnableModes = PTKModes.EditMode
        SubMode = PTKSubModes.PaintEditing
    end
    
    methods (Static)
        function results = RunPlugin(dataset, ~)
            if dataset.IsGasMRI
                results = dataset.GetResult('PTKThresholdLung');
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                results = dataset.GetResult('PTKThresholdLung');
            else
                results = dataset.GetResult('PTKLungROI');
                results = PTKGetInteriorLungRegion(results);
                results.ImageType = PTKImageType.Colormap;
            end
        end
    end
end