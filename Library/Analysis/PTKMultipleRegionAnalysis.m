function results = PTKMultipleRegionAnalysis(slice_bins, roi, context_mask, context_no_airways, distance_label, reporting)
    % Calculates metrics for an input image over multiple regions (bins).
    % 
    % Analysis is performed on the input image (roi). The context mask
    % defines which voxels wil be included in the analysis.
    % 
    % The slice_bins further divide the region of interest into a number
    % of sub regions, or bins. Metrics are then computed separately for
    % each bin.
    %
    % For example, the PTKDivideVolumeIntoSlices can be used to divide a
    % lung volume into thick slices in one of the coordinate directions,
    % and then PTKMultipleRegionAnalysis can be used to cqlculate 
    % metrics for each of these slices.
    % 
    % Parareters:
    %     slice_bins:
    %         defines the slices (bins). This is a structure with
    %         bin_image providing an image with all the regions and 
    %         bin_regions defining each region. See 
    %         PTKDivideVolumeIntoSlices for an example of how this is 
    %         constructed.
    %     roi:
    %         the input image
    %     context_mask:
    %         a mask for the whole image defining which voxels
    %         to included in the analysis
    %     context_mask:
    %         the context mask with the airways removed.
    %     distance_label: 
    %         a string defining the label to add to distance measurements
    %     reporting (CoreReporting):
    %          object for error reporting
    %
    % Returns:
    %     an array of PTKMetrics objects, one for each bin, containing measurements
    %         air tissue fraction (see PTKComputeAirTissueFraction)
    %         emphysema (see PTKComputeEmphysemaFromMask)
    %         region number and coordinates
    %         Distance form the lung base
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2014.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    
    results = PTKMetrics.empty();

    if isempty(context_mask) || ~context_mask.ImageExists
        return;
    end
    
    bin_image = slice_bins.BinImage;
    bin_regions = slice_bins.BinRegions;
    
    % Reduce all images to a consistent size
    bin_image.CropToFit;
    roi.ResizeToMatch(bin_image);
    context_mask.ResizeToMatch(bin_image);
    context_no_airways.ResizeToMatch(bin_image);
    
    reporting.UpdateProgressAndMessage(0, 'Calculating metrics for each bin');
    
    
    
    % Iterate over each bin
    for bin_index = 1 : numel(bin_regions)
        reporting.UpdateProgressStage(bin_index, numel(bin_regions));
        region = bin_regions(bin_index);
        bin_number = region.RegionNumber;
        bin_colour_index = region.ColormapIndex;
        distance_from_origin = region.DistanceFromOrigin;
        coordinates = region.Coordinates;
        
        % Create a mask for this bin
        mask = bin_image.BlankCopy();
        mask.ChangeRawImage(bin_image.RawImage == bin_colour_index & context_mask.RawImage);
        mask.CropToFit;
        
        % Create a mask for this bin excluding the airways
        no_airways_mask = bin_image.BlankCopy();
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
