function is_simple = PTKIsSimplePoint(image)
    % PTKIsSimplePoint. Determines if a point in a 3D binary image is a simple point.
    %
    %     A point is simple if removing it does not change the local
    %     connectivity of the surrounding points.
    %
    %     A faster implementation of this function can be found in
    %     PTKFastIsSimplePoint, which uses mex.
    %
    %     Based on algirithm by G Malandain, G Bertrand, 1992
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    

    global neighbours_26
    if (isempty(neighbours_26))
        CacheNeighbours([3 3 3]);
    end
    is_simple = GetNumberOfConnectedComponents(image, 26) && GetNumberOfConnectedComponents(~image, 6);
end

function is_n_cc_1 = GetNumberOfConnectedComponents(image, n)
global neighbours_logical_6 neighbours_logical_26
            
    if (n == 6)
        N6s = cat(3, [0,0,0;0,1,0;0,0,0], [0,1,0;1,0,1;0,1,0], [0,0,0;0,1,0;0,0,0]);
        N18s = cat(3, [0,1,0;1,1,1;0,1,0], [1,1,1;1,0,1;1,1,1], [0,1,0;1,1,1;0,1,0]);
        points_to_connect = N6s & image;
        points_that_can_be_visited = N18s & image;
        neighbours_logical = neighbours_logical_6;
    else
        N26s = ones(3,3,3); N26s(2,2,2) = 0;
        points_to_connect = N26s & image;
        points_that_can_be_visited = N26s & image;
        neighbours_logical = neighbours_logical_26;
    end
    
    index_of_first_point_to_connect = find(points_to_connect(:), 1);

    % If there are no image points connected to the centre, then this is
    % not a simple point since removing it will either create a hole or
    % remove an isolated point
    if (isempty(index_of_first_point_to_connect))
        is_n_cc_1 = false;
        return;        
    end
    
    points_that_can_be_visited(index_of_first_point_to_connect) = false;
    points_to_connect(index_of_first_point_to_connect) = false;
    
    next_points = false(3, 3, 3);
    next_points(index_of_first_point_to_connect) = true;
    
    while any(next_points(:))
          logical_neighbours = any(neighbours_logical(:, next_points(:)), 2);
          next_points(:) = logical_neighbours & points_that_can_be_visited(:);
          points_that_can_be_visited(logical_neighbours) = false;
    end
        
    is_n_cc_1 = ~any(points_to_connect(:) & points_that_can_be_visited(:));    
end
    

function CacheNeighbours(image_size)
global neighbours_26 neighbours_6 neighbours_logical_6 neighbours_logical_26

    neighbours_6 = {};
    neighbours_26 = {};
    for index = 1 : 27
        neighbours_26{index} = [];
        neighbours_6{index} = [];
        [i j k] = ind2sub(image_size, index);
        
        for i_o = -1:1             
            for j_o = -1:1
                for k_o = -1:1
                    % Avoid connectivity to self
                    if ((i_o ~= 0) || (j_o ~= 0) || (k_o ~= 0))
                        i_n = i+i_o;
                        j_n = j+j_o;
                        k_n = k+k_o;
                        
                        % Avoid connectivity to centre point
                        if ((i_n ~= 0) || (j_n ~= 0) || (k_n ~= 0))
                        
                            % Work out 26-connectivity
                            if ((i_n>=1) && (i_n<=3) && (j_n>=1) && (j_n<=3) && (k_n>=1) && (k_n<=3))
                                n_index = sub2ind(image_size, i_n, j_n, k_n);
                                neighbours_26{index} = [neighbours_26{index} n_index];
                                
                                % Work out 6-connectivity
                                if (abs(i_o)+abs(j_o)+abs(k_o)) == 1
                                    neighbours_6{index} = [neighbours_6{index} n_index];
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    neighbours_logical_6  = false(27, 27);
    neighbours_logical_26 = false(27, 27);
    for i = 1 : 27
        logical_6 = zeros(3,3,3);
        logical_6(neighbours_6{i}) = true;
        logical_26 = zeros(3,3,3);
        logical_26(neighbours_26{i}) = true;
        neighbours_logical_6(i, :) = logical_6(:);
        neighbours_logical_26(i, :) = logical_26(:);
    end
  
    neighbours_logical_6 = neighbours_logical_6';
    neighbours_logical_26 = neighbours_logical_26';
        
end