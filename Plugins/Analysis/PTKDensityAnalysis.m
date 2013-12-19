classdef PTKDensityAnalysis < PTKPlugin
    % PTKDensityAnalysis. Plugin for performing analysis of density using bins
    % along the cranial-caudal axis
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Density<br>analysis'
        ToolTip = 'Performs density analysis'
        Category = 'Analysis'

        Context = PTKContextSet.Any
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'DoNothing'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            
            % Get the density image
            roi = dataset.GetResult('PTKLungROI', PTKContext.LungROI);
            if ~roi.IsCT
                reporting.ShowMessage('PTKDensityAnalysis:NotCTImage', 'Cannot perform density analysis as this is not a CT image');
                return;
            end
            
            % Get a mask for the current region to analyse
            context_mask = dataset.GetTemplateImage(context);
            if ~context_mask.ImageExists
                context_mask = dataset.GetTemplateImage(PTKContext.Lungs);
            end
            
            context_mask.CropToFit;

            [~, airway_image] = dataset.GetResult('PTKAirways', PTKContext.LungROI);
            
            % Reduce all images to a consistent size
            airway_image.ResizeToMatch(context_mask);
            roi.ResizeToMatch(context_mask);
            
            % Create a region mask excluding the airways
            context_no_airways = context_mask.BlankCopy;
            context_no_airways.ChangeRawImage(context_mask.RawImage & airway_image.RawImage ~= 1);            
    
            results = PTKComputeAirTissueFraction(roi, context_mask, reporting);
            [emphysema_results, ~] = PTKComputeEmphysemaFromMask(roi, context_no_airways);
            results.Merge(emphysema_results);            
        end
    end
end