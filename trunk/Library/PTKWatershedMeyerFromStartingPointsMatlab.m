function labeled_output = TDWatershedMeyerFromStartingPointsMatlab(image, starting_labels)
    % TDWatershedMeyerFromStartingPointsMatlab. Implementation of Meyer flooding algorithm.
    %
    %     This is a Matlab-only implementation of the mex function
    %     TDWatershedMeyerFromStartingPoints. Use the mex function is possible
    %     as this is faster.
    %
    %     Inputs
    %     ------
    %
    %     image = 16-bit ingeter image (int16). The watershed regions grow according to the minima of these points
    %
    %     starting_labels - 8-bit integer (int8). Labels of starting points for the watershed
    %
    %     labeled_output - 8-bit integer (int8). Labels of the image assigned to
    %                       watershed regions. Watershed points are given the label -2
    %
    %     The watershed starts from the positive-valued labels in
    %     starting_labels and grows out into the zero-valued points, with the
    %     result returned in labeled_output. Regions starting from points with
    %     the same label can merge together. Negative labels are treated as
    %     fixed barriers. The do not grow and other regions cannot grow into
    %     them.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    disp('TDWatershedMeyerFromStartingPointsMatlab');
    warning('TDWatershedMeyerFromStartingPointsMatlab:MatlabVersion', 'This is a slow Matlab implementation of the mex function TDWatershedMeyerFromStartingPoints. For improved performance, use TDWatershedMeyerFromStartingPoints instead.');
    
    % Check inputs
    if (nargin ~= 2) 
        error('Two inputs are required: the image and a label matrix of the staring points.');
    end
    
    if (nargout > 1)
         error('TDWatershedMeyerFromStartingPointsMatlab produces one output but you have requested more.');
    end
    
    % Get the input images
    intensity_matrix = image;
    starting_indices = starting_labels;
    
    if ~isequal(size(image), size(starting_labels));
        error('The two input matrices must be of the same dimensions.');
    end
    
    intensity_data = intensity_matrix;
    startingpoints_data = starting_indices;

    % Our set of points uses a custom comparison function so it is automatically sorted by image intensity
    % but is guaranteed uniqueness in the voxel indices
    points_to_do = [];
    intensity_store = [];
    
    image_size = size(image);
    size_i = image_size(1);
    size_j = image_size(2);
    size_k = image_size(3);
    number_of_points = size_i*size_j*size_k;

    % Linear index offsets to nearest neighbours
    offsets = [1, -1, size_i, -size_i, size_i*size_j, -size_i*size_j];
    
    iteration_number = 0;
    max_iterations = 1000000000;

    % Initialise the output data
    output_data = startingpoints_data;

    % Populate the initial set of points
    initial_points = find(startingpoints_data > 0);
    for index = 1 : length(initial_points)
        point_index = initial_points(index);
        
        neighbours = point_index + offsets;
        neighbours = neighbours((neighbours > 0) & (neighbours <= number_of_points) & (output_data(neighbours) == 0));
        points_to_do = [points_to_do, neighbours];
        intensity_store = [intensity_store, intensity_data(neighbours)];
    end
    
    total_points = sum(starting_labels(:) == 0);
            
    % Iterate over remaining points
    while ~isempty(points_to_do)
        
        if (mod(iteration_number, 10000) == 0)
            points_left = sum(output_data(:) == 0);
            percentage_done = 100*(total_points - points_left)/total_points;
            disp(['Percentage done:' num2str(percentage_done)]);
        end
        
        [~, min_index] = min(intensity_store);
        point_index = points_to_do(min_index);
        points_to_do(min_index) = [];
        intensity_store(min_index) = [];
        
        label = output_data(point_index);
        
        % The point may already have been set
        if (label == 0)
            % Check nearest neighbours of this point
            neighbours = point_index + offsets;
            neighbours = neighbours((neighbours > 0) & (neighbours <= number_of_points));
            
            % Find label values of neighbours
            neighbour_labels = output_data(neighbours);
            
            % Ignore unset, watershed and boundary points
            neighbour_labels = unique(neighbour_labels(neighbour_labels > 0));
            
            % No labeled neighbour - this case should not be possible and
            % indidates a program error
            if isempty(neighbour_labels)
                error('No neighbouring point found - this case should never occur.');
            end
            
            if (numel(neighbour_labels) > 1)
                % More than one type of neighbouring label - mark as watershed point
                output_data(point_index) = -2;
            else
                
                % One neighbouring label found - mark this point
                output_data(point_index) = neighbour_labels;
                
                % Add neighbours to points-to-do
                neighbours = neighbours(output_data(neighbours) == 0);
                points_to_do = [points_to_do, neighbours];
                intensity_store = [intensity_store, intensity_data(neighbours)];
            end
        end
        
        iteration_number = iteration_number + 1;
        if (iteration_number > max_iterations)
            error('Error: Max Iteration number exceeded');
        end
    end
    labeled_output = output_data;
    disp(' - Completed TDWatershedMeyerFromStartingPointsMatlab');
end