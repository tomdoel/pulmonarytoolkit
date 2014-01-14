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
            bin_image = axial_bins.BinImage;
            bin_locations = axial_bins.BinLocations;
            bin_distance_from_base = axial_bins.BinDistancesFromBase;
            
            % Reduce all images to a consistent size
            bin_image.CropToFit;
            roi.ResizeToMatch(bin_image);
            context_mask.ResizeToMatch(bin_image);
            context_no_airways.ResizeToMatch(bin_image);
            
            reporting.UpdateProgressAndMessage(0, 'Calculating metrics for each axial bin');
            
            results = PTKMetrics.empty;
            
            % Iterate over each bin
            for bin_index = 1 : numel(bin_locations)
                reporting.UpdateProgressStage(bin_index, numel(bin_locations));

                % Create a mask for this bin
                mask = bin_image.BlankCopy;
                mask.ChangeRawImage(bin_image.RawImage == bin_index & context_mask.RawImage);
                mask.CropToFit;
                
                % Create a mask for this bin excluding the airways
                no_airways_mask = bin_image.BlankCopy;
                no_airways_mask.ChangeRawImage(bin_image.RawImage == bin_index & context_no_airways.RawImage);
                no_airways_mask.ResizeToMatch(mask);
                
                roi_reduced = roi.Copy;
                roi_reduced.ResizeToMatch(mask);
                bin_results = PTKComputeAirTissueFraction(roi_reduced, mask, reporting);
                [emphysema_results, ~] = PTKComputeEmphysemaFromMask(roi_reduced, no_airways_mask);
                bin_results.Merge(emphysema_results);
                bin_results.AddMetric('DistanceFromLungBaseMm', bin_distance_from_base(bin_index), 'Distance from lung base (mm)');
                bin_results.AddMetric('BinCoordinateMm', bin_locations(bin_index), 'Coordinate along cranial-caudal axis (mm)');
                
                results(end + 1) = bin_results;
            end
        end
    end
end