classdef PTKADCAnalysis < PTKPlugin
    % PTKADCAnalysis. Plugin for computing mean ADC values for DW gas MRI images
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
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'ADC<BR>analysis'
        ToolTip = 'Computes mean ADC values'
        Category = 'Analysis'

        Context = PTKContextSet.Any
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'DoNothing'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            
            if ~dataset.IsGasMRI
                reporting.ShowMessage('PTKADCAnalysis:NotGasMRIImage', 'Cannot perform ADC analysis as this is not a DW gas MRI image');
                return;
            end

            % Get the ventilation image
            adc = dataset.GetResult('PTKADC');
            
            % Get a mask for the current region to analyse
            context_mask = dataset.GetTemplateMask(context);
            
            % Special case if this context doesn't exist for this dataset
            if isempty(context_mask) || ~context_mask.ImageExists
                results = PTKMetrics.empty;
                return;
            end
            
            % Reduce all images to a consistent size
            adc.ResizeToMatch(context_mask);
    
            results = PTKComputeMeanADC(adc, context_mask);
        end
    end
end