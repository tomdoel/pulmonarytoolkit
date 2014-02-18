function results = PTKMultipleRegionAnalysis(slice_bins, roi, context_mask, context_no_airways, distance_label, reporting)
    % PTKMultipleRegionAnalysis. Calculates metrics based on bins
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    
    
    bin_image = slice_bins.BinImage;
    bin_regions = slice_bins.BinRegions;
    
    % Reduce all images to a consistent size
    bin_image.CropToFit;
    roi.ResizeToMatch(bin_image);
    context_mask.ResizeToMatch(bin_image);
    context_no_airways.ResizeToMatch(bin_image);
    
    reporting.UpdateProgressAndMessage(0, 'Calculating metrics for each bin');
    
    results = PTKMetrics.empty;
    
    
    % Iterate over each bin
    for bin_index = 1 : numel(bin_regions)
        reporting.UpdateProgressStage(bin_index, numel(bin_regions));
        region = bin_regions(bin_index);
        bin_number = region.RegionNumber;
        bin_colour_index = region.ColormapIndex;
        distance_from_origin = region.DistanceFromOrigin;
        coordinates = region.Coordinates;
        
        % Create a mask for this bin
        mask = bin_image.BlankCopy;
        mask.ChangeRawImage(bin_image.RawImage == bin_colour_index & context_mask.RawImage);
        mask.CropToFit;
        
        % Create a mask for this bin excluding the airways
        no_airways_mask = bin_image.BlankCopy;
        no_airways_mask.ChangeRawImage(bin_image.RawImage == bin_colour_index & context_no_airways.RawImage);
        no_airways_mask.ResizeToMatch(mask);
        
        roi_reduced = roi.Copy;
        roi_reduced.ResizeToMatch(mask);
        bin_results = PTKComputeAirTissueFraction(roi_reduced, mask, reporting);
        [emphysema_results, ~] = PTKComputeEmphysemaFromMask(roi_reduced, no_airways_mask);
        bin_results.Merge(emphysema_results);
        bin_results.AddMetric('RegionNumber', bin_number, 'Region Number');
        bin_results.AddMetric('DistanceFromLungBaseMm', distance_from_origin, distance_label);
        bin_results.AddMetric('RegionCoordinateX', coordinates.CoordX, 'Region Coordinates X (mm)');
        bin_results.AddMetric('RegionCoordinateY', coordinates.CoordY, 'Region Coordinates Y (mm)');
        bin_results.AddMetric('RegionCoordinateZ', coordinates.CoordZ, 'Region Coordinates Z (mm)');
        
        results(end + 1) = bin_results;
    end
end
