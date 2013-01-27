classdef PTKDensityAverage < PTKPlugin
    % PTKDensityAverage. Plugin for finding density averaged over a neighbourhood
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKDensityAverage computes the density of each voxel, averaged over a
    %     local neighbourhood.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Average Density'
        ToolTip = 'Compute the lung density averaged over a 3x3x3 neighbourhood'
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
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            reporting.ShowProgress('Fetching ROI');
            lung_roi = dataset.GetResult('PTKLungROI');
            mask = dataset.GetResult('PTKLeftAndRightLungs');
            [~, airways] = dataset.GetResult('PTKAirways');
            
            [density_average, density_average_mask] = PTKComputeDensityAverage(lung_roi, mask, airways, reporting);
            results = [];
            results.DensityAverage = density_average;
            results.DensityAverageMask = density_average_mask;
        end
        
         function results = GenerateImageFromResults(results, ~, ~)
             results = results.DensityAverage;
         end
    end
end