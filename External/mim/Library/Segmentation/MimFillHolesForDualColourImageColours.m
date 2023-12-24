function filled_image = MimFillHolesForDualColourImageColours(original_image, colour_1, colour_2)
    % Fills in holes in a colourmap image
    %
    % MimFillHolesForDualColourImageColours takes in a indexed image and fills in any completely
    % enclosed holes, where holes are regions of one the the colours 
    % surrounded completely by other the other colour or zero.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
        
    filled_image = FillHolesInImage(original_image, colour_1, colour_2);
    filled_image = FillHolesInImage(filled_image, colour_2, colour_1);
end

function filled_image_raw = FillHolesInImage(filled_image_raw, colour_1, colour_2)
    both_colours = [colour_1, colour_2];
    for colour = [colour_1, colour_2]
        other_colour = setdiff(both_colours, colour);
        connected_components_structure =  bwconncomp(filled_image_raw == colour, 6);
        labeled_components = labelmatrix(connected_components_structure);
        if connected_components_structure.NumObjects > 0
            edge_components = GetAllUnqiueValuesFromImageBoundaries(labeled_components);
            
            % We set label components to zero if they are not to be changed
            for component_index = edge_components'
                labeled_components(labeled_components == component_index) = 0;
            end
            
            % Find largest region
            num_pixels = cellfun(@numel, connected_components_structure.PixelIdxList);
            [~, sorted_largest_areas_indices] = sort(num_pixels, 'descend');
            largest_index = sorted_largest_areas_indices(1);
            labeled_components(labeled_components == largest_index) = 0;
            
            filled_image_raw(labeled_components > 0) = other_colour;
        end
    end
end

function edge_components = GetAllUnqiueValuesFromImageBoundaries(labeled_components)
      edge_components_1 = labeled_components([1, end], :, :); 
      edge_components_2 = labeled_components(:, [1, end], :); 
      edge_components_3 = labeled_components(:, :, [1, end]);
      edge_components = unique([edge_components_1(:); edge_components_2(:); edge_components_3(:)]);
end
