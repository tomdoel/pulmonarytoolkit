function results = PTKDivideVolumeIntoSlices(region_mask, dimension, reporting)
    % PTKDivideVolumeIntoSlices. Divides an image volume into a number of thick slices
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    
    [xc_mm, yc_mm, zc_mm] = region_mask.GetDicomCoordinates;
    midpoint_mm = [min(xc_mm(:)) + max(xc_mm(:)), min(yc_mm(:)) + max(yc_mm(:)), min(zc_mm(:)) + max(zc_mm(:))]/2;
    bounds = region_mask.GetBounds;
    coord_voxel_length_mm = region_mask.VoxelSize(dimension);
    
    % Get all values of coordinate between min and maximum values
    switch dimension
        case PTKImageOrientation.Axial
            coord_values = bounds(5) : bounds(6);
            coords = zc_mm;
        case PTKImageOrientation.Coronal
            coord_values = bounds(1) : bounds(2);
            coords = yc_mm;
        case PTKImageOrientation.Sagittal
            coord_values = bounds(3) : bounds(4);
            coords = xc_mm;
        otherwise
            reporting.Error('PTKDivideLungsIntoAxialBins:UnsupportedOrientation', 'The orientation was not recognised');
    end
    
    coord_values_mm = coords(coord_values);
    
    lung_base_mm = min(coord_values_mm) - coord_voxel_length_mm/2;
    lung_top_mm = max(coord_values_mm) + coord_voxel_length_mm/2;
    
    coord_offsets_for_all_voxels_mm = coords - lung_base_mm;
    
    % Compute the coordinates of the boundaries between bins
    bin_size_mm = 16;
    
    bin_locations = lung_base_mm + bin_size_mm/2 : bin_size_mm : lung_top_mm - bin_size_mm/2;
    bin_distance_from_base = bin_locations - lung_base_mm;
    
    % Compute bin numbers for each k coordinate
    bin_number = uint8(1 + max(0, floor(coord_offsets_for_all_voxels_mm/bin_size_mm)));
    
    switch dimension
        case PTKImageOrientation.Axial
            bin_matrix = repmat(shiftdim(bin_number, -2), region_mask.ImageSize(1), region_mask.ImageSize(2));
        case PTKImageOrientation.Coronal
            bin_matrix = repmat(bin_number, [1, region_mask.ImageSize(2), region_mask.ImageSize(3)]);
        case PTKImageOrientation.Sagittal
            bin_matrix = repmat(shiftdim(bin_number, -1), [region_mask.ImageSize(1), 1, region_mask.ImageSize(3)]);
        otherwise
            reporting.Error('PTKDivideLungsIntoAxialBins:UnsupportedOrientation', 'The orientation was not recognised');
    end
    
    bin_image_raw = bin_matrix.*uint8(region_mask.RawImage);
    bin_image = region_mask.BlankCopy;
    bin_image.ChangeRawImage(bin_image_raw);
    bin_image.ImageType = PTKImageType.Colormap;
    
    regions = PTKRegionDefinition.empty;
    for bin_index = 1 : numel(bin_distance_from_base)
        coordinates = PTKPoint(midpoint_mm(1), midpoint_mm(2), midpoint_mm(3));
        coordinates = PTKPoint.SetCoordinate(coordinates, dimension, bin_locations(bin_index));
        regions(bin_index) = PTKRegionDefinition(bin_index, bin_index, bin_distance_from_base(bin_index), coordinates);
    end
    
    results = [];
    results.BinImage = bin_image;
    results.BinLocations = bin_locations;
    results.BinDistancesFromBase = bin_distance_from_base;
    results.BinRegions = regions;
end
