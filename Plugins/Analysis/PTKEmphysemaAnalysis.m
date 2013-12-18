classdef PTKEmphysemaAnalysis < PTKPlugin
    % PTKEmphysemaAnalysis. Plugin for computing the percentage of emphysema
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
        ButtonText = 'Emphysema<br>analysis'
        ToolTip = 'Measures percentages of emphysema-like voxels'
        Category = 'Analysis'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        Context = PTKContextSet.Any
        PluginType = 'DoNothing'
        HidePluginInDisplay = true
        FlattenPreviewImage = true
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function emphysema_results = RunPlugin(dataset, context, reporting)
            lung_mask = dataset.GetTemplateImage(context);
            if ~lung_mask.ImageExists
                lung_mask = dataset.GetTemplateImage(PTKContext.Lungs);
            end
            
            roi = dataset.GetResult('PTKLungROI', PTKContext.LungROI);
            [~, airway_image] = dataset.GetResult('PTKAirways', PTKContext.LungROI);
            roi.ResizeToMatch(lung_mask);
            airway_image.ResizeToMatch(lung_mask);
            lung_mask_raw = lung_mask.RawImage;
            lung_mask_raw(airway_image.RawImage == 1) = 0;
            lung_mask.ChangeRawImage(lung_mask_raw);
            
            emphysema_results = PTKComputeEmphysemaFromMask(roi, lung_mask);
        end
    end
end