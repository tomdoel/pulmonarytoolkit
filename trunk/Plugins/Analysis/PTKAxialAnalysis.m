classdef PTKAxialAnalysis < PTKPlugin
    % PTKAxialAnalysis. Plugin for performing analysis of density using bins
    % along the cranial-caudal axis
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKAxialAnalysis divides the cranial-caudal axis into bins and
    %     performs analysis of the tissue density, air/tissue fraction and
    %     emphysema percentaein each bin.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Axial<br>analysis'
        ToolTip = 'Performs density analysis in bins along the cranial-caudal axis'
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
                reporting.ShowMessage('PTKAxialAnalysis:NotCTImage', 'Cannot perform density analysis as this is not a CT image');
                return;
            end
            
            % Get a mask for the current region to analyse
            context_mask = dataset.GetResult('PTKGetMaskForContext', context);

            % Create a region mask excluding the airways
            context_no_airways = dataset.GetResult('PTKGetMaskForContextExcludingAirways', context);
            
            % Divide the lung into bins along the cranial-caudal axis
            axial_bins = dataset.GetResult('PTKDivideLungsIntoAxialBins', PTKContext.Lungs);
            
            results = PTKMultipleRegionAnalysis(axial_bins, roi, context_mask, context_no_airways, reporting);
        end
        
    end
end