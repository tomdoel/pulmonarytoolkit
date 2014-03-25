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
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            reporting.ShowProgress('Fetching ROI');
            lung_roi = dataset.GetResult('PTKLungROI');
            lobes = dataset.GetResult('PTKLobes');
            lobes_mask = lobes.BlankCopy;
            lobes_mask.ChangeRawImage(lobes.RawImage > 0);
            
            mask = dataset.GetResult('PTKLungsExcludingSurface');
            non_parenchyma_points = dataset.GetResult('PTKLungInteriorNonParenchymaPoints');
            non_parenchyma_points_raw = non_parenchyma_points.RawImage;
            non_parenchyma_points_raw(lobes_mask.RawImage & ~mask.RawImage) = true;
            non_parenchyma_points.ChangeRawImage(non_parenchyma_points_raw);
            [density_average, density_values_computed_mask, density_valid_values_mask] = ...
                PTKComputeDensityAverage(lung_roi, lobes_mask, non_parenchyma_points, reporting);
            results = [];
            results.DensityAverage = density_average;
            results.DensityAverageMask = density_values_computed_mask;
            results.DensityAverageValidPointsMask = density_valid_values_mask;
        end
        
         function results = GenerateImageFromResults(results, ~, ~)
             results = results.DensityAverageMask;
             results.ImageType = PTKImageType.Colormap;
         end
    end
end