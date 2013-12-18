classdef PTKEmphysemaImage < PTKPlugin
    % PTKEmphysemaImage. Plugin for computing the percentage of emphysema
    %     voxels
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
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Emphysema<br>image'
        ToolTip = 'Shows emphysema-like voxels'
        Category = 'Analysis'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        Context = PTKContextSet.LungROI
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function emphysema_results = RunPlugin(dataset, context, reporting)
            lung_mask = dataset.GetResult('PTKLeftAndRightLungs');
            roi = dataset.GetResult('PTKLungROI');
            [~, airway_image] = dataset.GetResult('PTKAirways');
            airway_image.ResizeToMatch(lung_mask);
            lung_mask_raw = lung_mask.RawImage > 0;
            lung_mask_raw(airway_image.RawImage == 1) = false;
            lung_mask.ChangeRawImage(lung_mask_raw);            
            
            emphysema_results = PTKEmphysemaImage.GetEmphysemaImage(roi, lung_mask);
            emphysema_results.ImageType = PTKImageType.Colormap;
        end
    end
    
    methods (Static, Access = private)
        function emphysema_mask = GetEmphysemaImage(roi_data, mask)
            emphysema_threshold_value_hu = -950;
            emphysema_threshold_value = roi_data.HounsfieldToGreyscale(emphysema_threshold_value_hu);
            emphysema_mask_raw = (roi_data.RawImage <= emphysema_threshold_value) & (mask.RawImage);
            emphysema_mask = mask.BlankCopy;
            emphysema_mask.ChangeRawImage(3*uint8(emphysema_mask_raw));
        end
    end
end