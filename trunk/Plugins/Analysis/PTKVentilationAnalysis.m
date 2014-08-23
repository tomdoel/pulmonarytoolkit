classdef PTKVentilationAnalysis < PTKPlugin
    % PTKVentilationAnalysis. Plugin for computing ventilated volume percentage in
    %     gas MRI images
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
        ButtonText = 'Ventilation <BR>analysis'
        ToolTip = 'Computes ventilated volume of lung region (total and percentage)'
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
                reporting.ShowMessage('PTKDensityAnalysis:NotCTImage', 'Cannot perform density analysis as this is not a CT image');
                return;
            end

            % Get the ventilation image
            ventilation_mask = dataset.GetResult('PTKVentilationMask');
            
            % Get a mask for the current region to analyse
            context_mask = dataset.GetTemplateMask(context);
            
            % Special case if this context doesn't exist for this dataset
            if isempty(context_mask) || ~context_mask.ImageExists
                results = PTKMetrics.empty;
                return;
            end
            
            % Reduce all images to a consistent size
            ventilation_mask.ResizeToMatch(context_mask);
    
            results = PTKComputeVentilatedVolume(ventilation_mask, context_mask.RawImage);
        end
    end
end