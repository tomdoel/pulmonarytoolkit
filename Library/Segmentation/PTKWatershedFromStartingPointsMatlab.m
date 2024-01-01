function labeled_output = PTKWatershedFromStartingPointsMatlab(image, starting_labels)
    % A 3D watershed-like function.
    %
    % Attention:
    %     This is a Matlab-only implementation of the mex function
    %     PTKWatershedFromStartingPoints. It exists to prodive an alternative if the mex function
    %     cannot be compiled or for testing purposes.
    %
    %     Use the mex function PTKWatershedFromStartingPoints instead of using this function 
    %     if possible, as that is faster. 
    %
    % The watershed starts from the positive-valued labels in
    % starting_labels and grows out into the zero-valued points, with the
    % result returned in labeled_output. Regions starting from points with
    % the same label can merge together. Negative labels are treated as
    % fixed barriers. The do not grow and other regions cannot grow into
    % them.
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    

    disp('PTKWatershedFromStartingPointsMatlab.');
    warning('PTKWatershedFromStartingPointsMatlab:MatlabVersion', 'This is a slow Matlab implementation of the mex function PTKWatershedFromStartingPoints. For improved performance, use PTKWatershedFromStartingPoints instead.');
    
    % Check inputs
    if (nargin ~= 2) 
        error('Two inputs are required: the image and a label matrix of the staring points.');
    end
    
    if (nargout > 1)
         error('PTKwatershedFromStartingPoints produces one output but you have requested more.');
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
    %set<Point, classcomp> points_to_do;
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
        label = startingpoints_data(point_index);
        
        neighbours = point_index + offsets;
        neighbours = neighbours((neighbours > 0) & (neighbours <= number_of_points) & (output_data(neighbours) == 0));
        output_data(neighbours) = label;
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
        
        % Check nearest neighbours of this point
        neighbours = point_index + offsets;        
        neighbours = neighbours((neighbours > 0) & (neighbours <= number_of_points));
        neighbours = neighbours(output_data(neighbours) == 0);
        output_data(neighbours) = label;
        points_to_do = [points_to_do, neighbours];
        intensity_store = [intensity_store, intensity_data(neighbours)];
        
        iteration_number = iteration_number + 1;
        if (iteration_number > max_iterations)
            error('Error: Max Iteration number exceeded');
        end
    end
    labeled_output = output_data;
    disp(' - Completed PTKWatershedFromStartingPointsMatlab');
end
