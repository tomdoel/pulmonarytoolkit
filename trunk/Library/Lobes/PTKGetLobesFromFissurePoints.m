function result = PTKGetLobesFromFissurePoints(approximant_indices, lung_mask, image_size)
    % PTKGetLobesFromFissurePoints. Generates a lobar segmentation given fissure points.
    %
    %     PTKGetLobesFromFissurePoints is an intermediate stage in segmenting the
    %     lobes.
    %
    %     For more information, see
    %     [Doel et al., Pulmonary lobe segmentation from CT images using
    %     fissureness, airways, vessels and multilevel B-splines, 2012]
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    result = zeros(image_size, 'uint8');
    result(:) = 0;
     result(approximant_indices) = 1;
    result = SegmentLobesFromFissures(lung_mask, result, []);
    result = result.RawImage;    
end

function lobes = SegmentLobesFromFissures(lung_segmentation, fissure_image_raw, reporting)
    lobes = lung_segmentation.BlankCopy;    
    lobes_raw = SegmentLobesFromFissuresRaw(lung_segmentation.RawImage, fissure_image_raw, reporting);
    lobes.ChangeRawImage(lobes_raw);
    lobes.ImageType = PTKImageType.Colormap;
end

function lobes_raw = SegmentLobesFromFissuresRaw(lung_segmentation_raw, fissure_image_raw, reporting)
    indices = find(fissure_image_raw(:));

    z_offset = size(fissure_image_raw, 1)*size(fissure_image_raw, 2);
    starting_indices_above = indices - z_offset;
    starting_indices_below = indices + z_offset;
    lobes_raw = FillFromFissures(lung_segmentation_raw, starting_indices_above, starting_indices_below, reporting);
end

function mask = FillFromFissures(mask, starting_indices_above, starting_indices_below, reporting)
    mask = uint8(mask); % The mask may be logical, so we need to change it to an integer type
    [i_offset, j_offset, k_offset] = GetOffsets(size(mask));
    linear_offsets_6way = [i_offset, -i_offset, j_offset, -j_offset, k_offset, -k_offset];
    linear_offsets_up_left = [-k_offset, -i_offset];
    linear_offsets_down_right = [k_offset, i_offset];

    number_points = length(mask(:));

    % First fill only in preferential directions, to prevent lobes
    % enroaching on each other
    mask = FillForTheseNeighboursDouble(mask, starting_indices_above, starting_indices_below, linear_offsets_up_left, linear_offsets_down_right, number_points, 2, 3, reporting);
    
    % Now fill in the gaps
    next_points_1 = find(mask == 2);
    next_points_2 = find(mask == 3);
    mask = FillForTheseNeighboursDouble(mask, next_points_1, next_points_2, linear_offsets_6way, linear_offsets_6way, number_points, 2, 3, reporting); 
end

function mask = FillForTheseNeighboursDouble(mask, next_points_1, next_points_2, linear_offsets_1, linear_offsets_2, number_points, label_colour_1, label_colour_2, reporting)
    while ~isempty(next_points_1) || ~isempty(next_points_2)
        if ~isempty(next_points_1)
            next_points_1 = ProcessNextPoints(mask, next_points_1, linear_offsets_1, number_points);
            mask(next_points_1) = label_colour_1;
        end

        if ~isempty(next_points_2)
            next_points_2 = ProcessNextPoints(mask, next_points_2, linear_offsets_2, number_points);
            mask(next_points_2) = label_colour_2;
        end
        
    end
end

function next_points = ProcessNextPoints(mask, next_points, linear_offsets, number_points)
    next_points = GetNeighbouringPoints(next_points, linear_offsets, number_points);
    next_points = next_points(mask(next_points) == 1)';
    next_points = next_points';
end

function list_of_point_indices = GetNeighbouringPoints(point_indices, linear_offsets, number_points)
    list_of_point_indices = repmat(point_indices, 1, length(linear_offsets)) + repmat(linear_offsets, length(point_indices), 1);
    list_of_point_indices = unique(list_of_point_indices(:));
    list_of_point_indices = list_of_point_indices(list_of_point_indices > 0 & list_of_point_indices <= number_points);
end

function [i_offset, j_offset, k_offset] = GetOffsets(pic_size)
    cube_indices = [1:27];
    [i j k] = ind2sub([3 3 3], cube_indices);
    pic_indices = sub2ind(pic_size, i, j, k);
    pic_offsets = pic_indices(14) - pic_indices;
    k_offset = pic_offsets(5);
    j_offset = pic_offsets(11);
    i_offset = pic_offsets(13);
end



