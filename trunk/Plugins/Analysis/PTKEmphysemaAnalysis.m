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
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function emphysema_results = RunPlugin(dataset, context, reporting)
            
            % Get a mask for the current region to analyse
            context_mask = dataset.GetTemplateMask(context);

            % Special case if this context doesn't exist for this dataset
            if isempty(context_mask) || ~context_mask.ImageExists
                emphysema_results = PTKMetrics.empty;
                return;
            end
            
            roi = dataset.GetResult('PTKLungROI', PTKContext.LungROI);
            [~, airway_image] = dataset.GetResult('PTKAirways', PTKContext.LungROI);
            roi.ResizeToMatch(context_mask);
            airway_image.ResizeToMatch(context_mask);
            lung_mask_raw = context_mask.RawImage;
            lung_mask_raw(airway_image.RawImage == 1) = 0;
            context_mask.ChangeRawImage(lung_mask_raw);
            
            emphysema_results = PTKComputeEmphysemaFromMask(roi, context_mask);
        end
    end
end