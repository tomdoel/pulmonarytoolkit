// TDWatershedMeyerFromStartingPoints. Implementation of Meyer flooding algorithm.
//
//     This is a Matlab MEX function and must be compled before use. To compile, type 
//
//         mex TDWatershedMeyerFromStartingPoints
//
//     on the Matlab command line.
//
//     This is an optimised adaption of the algorithm by G Malandain, G Bertrand, 1992
//
//     Alternatively, you can use the Matlab-only implementation TDWatershedMeyerFromStartingPointsMatlab 
//     which is equivalent to this function but slower as it does not use mex files. 
//
//     Syntax
//     ------
//         labeled_output = TDWatershedMeyerFromStartingPoints(image, starting_labels [, max_num_iterations])
//
//     Inputs
//     ------
//         image = 16-bit ingeter image (int16). The watershed regions grow according to the minima of these points
//
//         starting_labels - 8-bit integer (int8). Labels of starting points for the watershed
//
//         max_num_iterations (optional) - The algorithm will terminate if the number of iterations 
//                                         (one per point allocated) goes above this value
//
//     Output
//     ------
//         labeled_output - 8-bit integer (int8). Labels of the image assigned 
//             to watershed regions. Watershed points are given the label -2
// 
// 
//     The watershed starts from the positive-valued labels in starting_labels and grows out into the
//     zero-valued points, with the result returned in labeled_output.
//     Regions starting from points with the same label can merge together.
//     Negative labels are treated as fixed barriers. The do not grow and other regions cannot grow into them.
//
//
//     Licence
//     -------
//     Part of the TD Pulmonary Toolkit. www.tomdoel.com
//     www.tomdoel.com
//     Distributed under the GNU GPL v3 licence. Please see website for details.
//

#include <set>
#include "mex.h"


using namespace std;

extern void _main();

typedef struct Size {
    mwSize size[3];    
} Size;

Size GetDimensions(const mxArray* array) {
    Size dimensions;
    
    mwSize number_of_dimensions = mxGetNumberOfDimensions(array);
    const mwSize* array_dimensions = mxGetDimensions(array);
         
    if (number_of_dimensions > 3) {
        mexErrMsgTxt("The input matricies must have 2 or 3 dimensions.");
    }
             
    dimensions.size[0] = array_dimensions[0];
    dimensions.size[1] = array_dimensions[1];
    dimensions.size[2] = 1;
    if (number_of_dimensions > 2) {
        dimensions.size[2] = array_dimensions[2];
    }
    
    return dimensions;
};

typedef pair<int, short int> Point;
typedef set<Point> PointSet;

// Custom compare function for our set of points. We need this because we are sorting by intensity 
// value (the second value in the pair) but we use the voxel index (first value) for uniqueness.
// Note that this function is used to determine equality (if !lhs<rhs && !rhs<lhs) and therefore
// we must also use the first value if the second values are equal
struct classcomp {
    bool operator() (const Point& lhs, const Point& rhs) const {
        if (lhs.second == rhs.second) {
            return lhs.first < rhs.first;
        } else {
            return lhs.second < rhs.second;
        }
    }
};

// The main function call
void mexFunction(int num_outputs, mxArray* pointers_to_outputs[], int num_inputs, const mxArray* pointers_to_inputs[])
{
    mexPrintf("TDWatershedMeyerFromStartingPoints\n"); 
    
    // Check inputs
    if ((num_inputs < 2) || (num_inputs > 3)) {
        mexErrMsgTxt("Two inputs are required: the image and a label matrix of the staring points. The third optional input is the maximum number of iterations");
    }
    
    if (num_outputs > 1) {
         mexErrMsgTxt("TDWatershedMeyerFromStartingPoints produces one output but you have requested more.");
    }
    
    // Get the input images
    const mxArray* intensity_matrix = pointers_to_inputs[0];
    const mxArray* starting_indices = pointers_to_inputs[1];

    bool max_iter_set_manually = false;
    int max_iterations = 1000000000;
    if (num_inputs == 3) {
        if ((!mxIsNumeric(pointers_to_inputs[2])) || (mxGetNumberOfElements(pointers_to_inputs[2]) != 1) || mxIsComplex(pointers_to_inputs[2])) {
            mexErrMsgTxt("The maximum number of iterations must be noncomplex integer.");
        }
        max_iterations = mxGetScalar(pointers_to_inputs[2]);
        max_iter_set_manually = true;
    }
    
    Size dimensions = GetDimensions(intensity_matrix);
    Size dimensions_starting_points = GetDimensions(starting_indices);
    if (dimensions_starting_points.size[0] != dimensions.size[0] || dimensions_starting_points.size[1] != dimensions.size[1] 
            || dimensions_starting_points.size[2] != dimensions.size[2]) {
        mexErrMsgTxt("The two input matrices must be of the same dimensions.");
    }
    
    if (mxGetClassID(intensity_matrix) != mxINT16_CLASS || mxIsComplex(intensity_matrix)) {
        mexErrMsgTxt("Input image must be noncomplex int16.");
    }
    
    if (mxGetClassID(starting_indices) != mxINT8_CLASS || mxIsComplex(starting_indices)) {
        mexErrMsgTxt("Starting_indices must be noncomplex int8.");
    }
    
    // Create mxArray for the output data    
    mxArray* output_array = mxCreateNumericArray(3, dimensions.size, mxINT8_CLASS, mxREAL);
    pointers_to_outputs[0] = output_array;
    
    short int* intensity_data = (short int*)mxGetData(intensity_matrix);
    char* startingpoints_data = (char*)mxGetData(starting_indices);
    char* output_data = (char*)mxGetData(pointers_to_outputs[0]);

    // Our set of points uses a custom comparison function so it is automatically sorted by image intensity
    // but is guaranteed uniqueness in the voxel indices
    set<Point, classcomp> points_to_do;
    
    int size_i = dimensions.size[0];
    int size_j = dimensions.size[1];
    int size_k = dimensions.size[2];
    int number_of_points = size_i*size_j*size_k;

    
    int multiples[3];
    multiples[0] = 1;
    multiples[1] = size_i;
    multiples[2] = size_i*size_j;
    
    int iteration_number = 0;
    
    // Linear index offsets to nearest neighbours
    const int number_of_nearest_neighbours = 6;
    int offsets[number_of_nearest_neighbours];
    offsets[0] = 1;
    offsets[1] = -1;
    offsets[2] = size_i;
    offsets[3] = -size_i;
    offsets[4] = size_i*size_j;
    offsets[5] = -size_i*size_j;

//     const int number_of_nearest_neighbours = 26;
//     int offsets[number_of_nearest_neighbours];
//     {
//         int index_offset = 0;
//         
//         for (int i = -1; i < 2; i++) {
//             for (int j = -1; j < 2; j++) {
//                 for (int k = -1; k < 2; k++) {
//                     if ((i != 0) || (j != 0) || (k != 0)) {
//                         offsets[index_offset] = i*multiples[0] + j*multiples[1] + k*multiples[2];
//                         mexPrintf("-Offset %d\n", offsets[index_offset]);
//                         index_offset++;
//                     }
//                 }
//             }
//         }
//     }


    mexPrintf("-Initial population\n");

    // Initialise the output data
    for (int point_index = 0; point_index < number_of_points; point_index++) {
        char label = startingpoints_data[point_index];
        
        // Initialise output data
        output_data[point_index] = label;
    }

    
    // Populate the initial set of points and initialise the output data
    for (int point_index = 0; point_index < number_of_points; point_index++) {
        char label = startingpoints_data[point_index];
        
        // Only positive labels are used as initial points.
        // Negative labels are treated as fixed barriers.
        if (label > 0) {
            
            // Check nearest neighbours of this point
            for (int offset_index = 0; offset_index < number_of_nearest_neighbours; offset_index++) {
                int neighbour_index = point_index + offsets[offset_index];
                if ((neighbour_index >=0) && (neighbour_index < number_of_points)) {
                    if (output_data[neighbour_index] == 0) {
                        // Add this point to the set (with a suggested position which speeds up the addition).
                        points_to_do.insert(points_to_do.begin(), Point(neighbour_index, intensity_data[neighbour_index]));
                    }
                }
            }
        }
    }
    
    mexPrintf("-Starting Loop\n");
            
    // Iterate over remaining points
    while (!points_to_do.empty()) {
        
        // Get next point (this will be the one with the smallest intensity)
       set<Point, classcomp>::iterator first_point_iterator = points_to_do.begin();
        Point first_point = *first_point_iterator;
        int point_index = first_point.first;
        
        // Remove from the set
        points_to_do.erase(first_point_iterator);

        // The point may already have been set
        if (output_data[point_index] == 0) {
        
            char label_for_this_point = 0;
            
            // Check nearest neighbours to find a label
            for (int offset_index = 0; offset_index < number_of_nearest_neighbours; offset_index++) {
                int neighbour_index = point_index + offsets[offset_index];
                if ((neighbour_index >=0) && (neighbour_index < number_of_points)) {
                    
                    // Find the label of this neighbour
                    char neighbour_label = output_data[neighbour_index];
                    
                    // Look for labeled neighbours
                    if (neighbour_label > 0) {
                        
                        // If no label has yet been chosen, choose this one
                        if (label_for_this_point == 0) {
                            label_for_this_point = neighbour_label;
                            
                            // Otherwise check whether the label is the same
                        } else {
                            if (label_for_this_point != neighbour_label) {
                                
                                // More than one labeled neighbour - mark as watershed
                                label_for_this_point = -2;
                            }
                        }
                    }
                }
            }
            
            if (label_for_this_point == 0) {
                mexErrMsgTxt("No neighbouring point found - this case should never occur.");
            }
            
            // Label this point
            output_data[point_index] = label_for_this_point;
            
            // If the point is not a watershed, add neighbours to the points to consider
            if (label_for_this_point > 0) {
                
                // Check nearest neighbours of this point
                for (int offset_index = 0; offset_index < number_of_nearest_neighbours; offset_index++) {
                    int neighbour_index = point_index + offsets[offset_index];
                    if ((neighbour_index >=0) && (neighbour_index < number_of_points)) {
                        if (output_data[neighbour_index] == 0) {
                            // Add this point to the set (with a suggested position which speeds up the addition).
                            points_to_do.insert(points_to_do.begin(), Point(neighbour_index, intensity_data[neighbour_index]));
                        }
                    }
                }
            }
        }
        
        iteration_number++;
        if (iteration_number > max_iterations) {
            if (max_iter_set_manually) {
                mexWarnMsgTxt("Terminating as the specified maximum iteration number has been reached");
                return;
            } else {
                mexErrMsgTxt("Error: Maximum number of iterations has been exceeded");
            }
        }
    }
    
    mexPrintf(" - Completed TDWatershedMeyerFromStartingPoints\n");
    return;
}
