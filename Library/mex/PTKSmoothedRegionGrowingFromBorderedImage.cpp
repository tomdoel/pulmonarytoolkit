// PTKSmoothedRegionGrowingFromBorderedImage. Performs region growing into a 
//   masked region from multiple starting points, using an algorithm which 
//   results in smoothed image boundaries.
//
//   See the Matlab functon PTKSmoothedRegionGrowing.m for how to use this function.
//
//     This is a Matlab MEX function and must be compled before use. To compile, type
//
//         mex PTKSmoothedRegionGrowingFromBorderedImage
//
//     on the Matlab command line.
//
//
//     Syntax
//     ------
//         labeled_output = PTKSmoothedRegionGrowingFromBorderedImage(labelled_input, smoothing_structural_element [, max_num_iterations])
//
//     Inputs
//     ------
//         labelled_input = 8-bit integer image (int8) of labels for the image regions and mask.
//           Positive values represent starting points for each region (one region for each positive value).
//           Zero values represent the mask of voxels the region growing should grow into.
//           Negative values are fixed points and regions will not grow into these voxels.
//           
//           NOTE: labelled_input must contain a border region of regative values, 
//           with the border size in each dimension being (at least) one voxel less 
//           than the size of structural element in the corresponding dimension.
//
//         smoothing_structural_element = 8-bit integer image (int8) where zero 
//           values are outside of the structural element and positive values are inside.
//           This represents the structural element used for smoothing
//
//         max_num_iterations (optional) - The algorithm will terminate if the number of iterations
//                                         (one per point allocated) goes above this value
//
//     Output
//     ------
//         labeled_output - 8-bit integer (int8). Labels of the image assigned
//             to regions after the growing algorithm terminates. Regions outside the mask are given value -1.
//
//
//     This function is best not invoked directly, but instead called via the Matlab funciton
//     PTKSmoothedRegionGrowing.m 
//
//     At each iteration, each region grows into its nearest neighbour voxels. 
//     Growing only occurs if the neighbourhood of the new voxel (definied by the structural element)
//     contains more voxels of that label colour than of any other label.
//     Using a spherical structural element will result in a smoothed image boundary between the regions.
//
//
//    Licence
//    -------
//    Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
//    Author: Tom Doel, 2013.  www.tomdoel.com
//    Distributed under the GNU GPL v3 licence. Please see website for details.
//
//

#include <set>
#include <map>
#include <vector>
#include "mex.h"


using namespace std;

extern void _main();

typedef struct Size {
    mwSize size[3];
} Size;

typedef struct Size4 {
    mwSize size[4];
} Size4;

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

typedef unsigned int NeibourCountsType;
typedef signed char LabelledInputType;
typedef map<LabelledInputType, LabelledInputType> LabelMap;
typedef signed char SmoothingElementType;
typedef signed char OutputType;
typedef long PointType;
typedef long DimensionSizeType;
typedef set<PointType> PointSet;
typedef vector<PointType> PointVector;
typedef vector<DimensionSizeType> SizeVector;


void Ind2Sub(const PointVector& image_size, const PointType& point_index, DimensionSizeType& ic, DimensionSizeType& jc, DimensionSizeType& kc) {
    DimensionSizeType size_i = image_size[0];
    DimensionSizeType size_j = image_size[1];
    DimensionSizeType size_k = image_size[2];
    
    // Compute coordiates for point
    kc = point_index/(size_i*size_j);
    jc = (point_index - kc*size_i*size_j)/size_i;
    ic = point_index - (jc*size_i + kc*size_i*size_j);    
}



void AddPoint(NeibourCountsType* neighbour_counts, const LabelMap& neighbour_map, LabelledInputType* labelled_input_data, SmoothingElementType* smoothing_element_data, OutputType* output_data, const SizeVector& labelled_image_size, const SizeVector& smoothing_element_size, PointType point_index, const LabelledInputType& label_map_index) {
    DimensionSizeType size_i = labelled_image_size[0];
    DimensionSizeType size_j = labelled_image_size[1];
    DimensionSizeType size_k = labelled_image_size[2];
    DimensionSizeType size_se_i = smoothing_element_size[0];
    DimensionSizeType size_se_j = smoothing_element_size[1];
    DimensionSizeType size_se_k = smoothing_element_size[2];
    DimensionSizeType i_offset = size_se_i/2;
    DimensionSizeType j_offset = size_se_j/2;
    DimensionSizeType k_offset = size_se_k/2;
    PointVector multiples(3);
    multiples[0] = 1;
    multiples[1] = size_i;
    multiples[2] = size_i*size_j;    
    
    PointType number_of_points = size_i*size_j*size_k;
    
    long number_of_labels = neighbour_map.size();
    
    PointType map_offset = (long)label_map_index*number_of_points;
    PointType neighbour_counts_index = point_index - i_offset*multiples[0] - j_offset*multiples[1] - k_offset*multiples[2] + map_offset;
    PointType se_index = 0;
    
    // Iterate through the structural element
    for (DimensionSizeType kc_se = 0; kc_se < size_se_k; kc_se++) {
        for (DimensionSizeType jc_se = 0; jc_se < size_se_j; jc_se++) {
            for (DimensionSizeType ic_se = 0; ic_se < size_se_i; ic_se++) {
                
                // Only consider points within the structural element
                if (smoothing_element_data[se_index] > 0) {
                    
                    // Increase the neighbour counts for this voxel by one
                    neighbour_counts[neighbour_counts_index] += 1;                    
                }
                neighbour_counts_index += 1;
                se_index += 1;
            }
            neighbour_counts_index += multiples[1] - size_se_i;
        }
        neighbour_counts_index += multiples[2] - size_se_j*multiples[1];
    }
    
}



void InitialiseCountsArray(NeibourCountsType* neighbour_counts, LabelMap& neighbour_map, LabelledInputType* labelled_input_data, SmoothingElementType* smoothing_element_data, signed char* output_data, const SizeVector& labelled_image_size, const SizeVector& smoothing_element_size) {
    
    DimensionSizeType size_i = labelled_image_size[0];
    DimensionSizeType size_j = labelled_image_size[1];
    DimensionSizeType size_k = labelled_image_size[2];
    
    PointType multiples[3];
    multiples[0] = 1;
    multiples[1] = size_i;
    multiples[2] = size_i*size_j;
    
    // Iterate through every point in the image
    for (DimensionSizeType ic = 0; ic < size_i; ic++) {
        for (DimensionSizeType jc = 0; jc < size_j; jc++) {
            for (DimensionSizeType kc = 0; kc < size_k; kc++) {
                PointType point_index = ic*multiples[0] + jc*multiples[1] + kc*multiples[2];
                if (labelled_input_data[point_index] > 0) {
                    LabelledInputType label_at_this_point = labelled_input_data[point_index];
                    LabelledInputType label_map_index = neighbour_map.at(label_at_this_point);
                    
                    AddPoint(neighbour_counts, neighbour_map, labelled_input_data, smoothing_element_data, output_data, labelled_image_size, smoothing_element_size, point_index, label_map_index);
                }
            }
        }
    }
    
}

PointSet GetInitialPointSet(LabelledInputType* labelled_input_data, PointType number_of_points, const PointVector& offsets) {
    
    PointSet points_to_do;
    const PointVector::size_type number_of_nearest_neighbours = offsets.size();
    
    // Populate the initial set of points and initialise the output data
    for (PointType point_index = 0; point_index < number_of_points; point_index++) {
        LabelledInputType label = labelled_input_data[point_index];
        
        // Only positive labels are used as initial points.
        // Negative labels are treated as fixed barriers.
        if (label > 0) {
            
            // Check nearest neighbours of this point
            for (int offset_index = 0; offset_index < number_of_nearest_neighbours; offset_index++) {
                PointType neighbour_index = point_index + offsets[offset_index];
                if ((neighbour_index >=0) && (neighbour_index < number_of_points)) {
                    if (labelled_input_data[neighbour_index] == 0) {

                        points_to_do.insert(points_to_do.begin(), neighbour_index);
                    }
                }
            }
        }
    }
    return(points_to_do);
}


LabelMap GetLabelMap(LabelledInputType* labelled_input_data, const SizeVector& labelled_image_size) {
    DimensionSizeType size_i = labelled_image_size[0];
    DimensionSizeType size_j = labelled_image_size[1];
    DimensionSizeType size_k = labelled_image_size[2];
    PointVector multiples(3);
    multiples[0] = 1;
    multiples[1] = size_i;
    multiples[2] = size_i*size_j;
    
    // Determine the number of labels and map them to sequental values 0,1,2,..
    LabelledInputType num_labels = 0;
    LabelMap label_mapping;
    for (DimensionSizeType ic = 0; ic < size_i; ic++) {
        for (DimensionSizeType jc = 0; jc < size_j; jc++) {
            for (DimensionSizeType kc = 0; kc < size_k; kc++) {
                PointType point_index = ic*multiples[0] + jc*multiples[1] + kc*multiples[2];
                LabelledInputType input_label = labelled_input_data[point_index];
                if (input_label > 0) {
                    if (label_mapping.find(input_label) == label_mapping.end()) {
                        label_mapping[input_label] = num_labels;
                        num_labels += 1;
                    }
                }
            }
        }
    }

    if (num_labels == 0) {
        mexErrMsgTxt("Input image is empty");
    }
    
    return(label_mapping);
}

NeibourCountsType* CreateNeighbourCountsMatrix(const SizeVector& neighbour_count_size) {
    PointType num_labels = neighbour_count_size[3];
    PointType number_of_points = (PointType)(neighbour_count_size[0])*(PointType)(neighbour_count_size[1])*(PointType)(neighbour_count_size[2]);
    PointType size_of_count_buffer = num_labels*number_of_points;
    
    NeibourCountsType* neighbour_counts = (NeibourCountsType*)mxCalloc(size_of_count_buffer, sizeof(NeibourCountsType));
    if (neighbour_counts == 0) {
        mexErrMsgTxt("Memory could not be allocated.");
    }
    
    return(neighbour_counts);
}

LabelMap::size_type GetLabelWithMaximumCounts(NeibourCountsType* neighbour_counts, const SizeVector& neighbour_count_size, const PointType& point_index) {
    PointType number_of_points_in_image = neighbour_count_size[0]*neighbour_count_size[1]*neighbour_count_size[2];
    PointType num_labels = neighbour_count_size[3];
     
    NeibourCountsType max_neighbour_count = 0;
    LabelMap::size_type maximum_neighbour_index = 0;
    
    for (long label_index = 0; label_index < num_labels; label_index++) {
        PointType neighbour_counts_point_index = label_index*number_of_points_in_image + point_index;
        if (neighbour_counts[neighbour_counts_point_index] > max_neighbour_count) {
            max_neighbour_count = neighbour_counts[neighbour_counts_point_index];
            maximum_neighbour_index = label_index;
        }
    }
    return(maximum_neighbour_index);
}

LabelledInputType GetLabelFromIndex(const LabelMap& label_mapping, int maximum_counts_label_index) {
    for (LabelMap::const_iterator label_iterator = label_mapping.begin(); label_iterator != label_mapping.end(); label_iterator++) {
        if (label_iterator->second == maximum_counts_label_index) {
            return(label_iterator->first);
        }
    }
    mexErrMsgTxt("No neighbour count found.");
    return(-1);
}

LabelledInputType FindAndSetPoint(NeibourCountsType* neighbour_counts, const SizeVector& neighbour_count_size, const LabelMap& neighbour_map, LabelledInputType* labelled_input_data, SmoothingElementType* smoothing_element_data, OutputType* output_data, const SizeVector& labelled_image_size, const SizeVector& smoothing_element_size, PointType point_index, const PointVector& offsets) {
    int maximum_counts_label_index = GetLabelWithMaximumCounts(neighbour_counts, neighbour_count_size, point_index);
    LabelledInputType maximum_counts_label = GetLabelFromIndex(neighbour_map, maximum_counts_label_index);
    
    PointVector::size_type number_of_nearest_neighbours = offsets.size();
    PointType number_of_points = labelled_image_size[0]*labelled_image_size[1]*labelled_image_size[2];    

    // Check nearest neighbours to find a label
    for (DimensionSizeType offset_index = 0; offset_index < number_of_nearest_neighbours; offset_index++) {
        PointType neighbour_index = point_index + offsets[offset_index];
        if ((neighbour_index >=0) && (neighbour_index < number_of_points)) {
            
            // Find the label of this neighbour
            LabelledInputType neighbour_label = output_data[neighbour_index];
            if (neighbour_label == maximum_counts_label) {
                output_data[point_index] = maximum_counts_label;
                AddPoint(neighbour_counts, neighbour_map, labelled_input_data, smoothing_element_data, output_data, labelled_image_size, smoothing_element_size, point_index, maximum_counts_label_index);
                return(maximum_counts_label);
            }
        }
    }
    
    return(0);
}

void SmoothedRegionGrowing(LabelledInputType* labelled_input_data, SmoothingElementType* smoothing_element_data, OutputType* output_data, unsigned long max_iterations, const SizeVector& labelled_image_size, const SizeVector& smoothing_element_size, const bool& max_iter_set_manually)
{
    // Set up some variables
    DimensionSizeType size_i = labelled_image_size[0];
    DimensionSizeType size_j = labelled_image_size[1];
    DimensionSizeType size_k = labelled_image_size[2];
    
    PointVector multiples(3);
    multiples[0] = 1;
    multiples[1] = size_i;
    multiples[2] = size_i*size_j;
    
    unsigned long iteration_number = 0;
        
    // Linear index offsets to nearest neighbours
    const int number_of_nearest_neighbours = 6;
    PointVector offsets(number_of_nearest_neighbours);
    offsets[0] = 1;
    offsets[1] = -1;
    offsets[2] = size_i;
    offsets[3] = -size_i;
    offsets[4] = size_i*size_j;
    offsets[5] = -size_i*size_j;

    PointType number_of_points = labelled_image_size[0]*labelled_image_size[1]*labelled_image_size[2];
    
    // Get the map from input labels to a sequential vector 0,1,2,...
    LabelMap label_mapping = GetLabelMap(labelled_input_data, labelled_image_size);
    
    long num_labels = label_mapping.size();
    SizeVector neighbour_count_size(4);
    neighbour_count_size[0] = labelled_image_size[0];
    neighbour_count_size[1] = labelled_image_size[1];
    neighbour_count_size[2] = labelled_image_size[2];
    neighbour_count_size[3] = num_labels;
    
    // Create the neighbourhood count matrix
    NeibourCountsType* neighbour_counts = CreateNeighbourCountsMatrix(neighbour_count_size);
    
    // Initialise the neighbourhood count matrix
    InitialiseCountsArray(neighbour_counts, label_mapping, labelled_input_data, smoothing_element_data, output_data, labelled_image_size, smoothing_element_size);
    
    PointSet new_set_of_points = GetInitialPointSet(labelled_input_data, number_of_points, offsets);

    
    
    while (!new_set_of_points.empty()) {
        
        PointSet points_to_do = new_set_of_points;
        new_set_of_points.clear();
        
        // Iterate over remaining points
        while (!points_to_do.empty()) {

            // Get next point
            PointSet::iterator first_point_iterator = points_to_do.begin();
            PointType point_index = *first_point_iterator;
            
            // Remove from the set
            points_to_do.erase(first_point_iterator);
            
            // The point may already have been set
            if (output_data[point_index] == 0) {
                
                LabelledInputType label_for_this_point = FindAndSetPoint(neighbour_counts, neighbour_count_size, label_mapping, labelled_input_data, smoothing_element_data, output_data, labelled_image_size, smoothing_element_size, point_index, offsets);
                                
                // Add neighbours to the points to consider
                if (label_for_this_point > 0) {
                    
                    // Check nearest neighbours of this point
                    for (int offset_index = 0; offset_index < number_of_nearest_neighbours; offset_index++) {
                        int neighbour_index = point_index + offsets[offset_index];
                        if ((neighbour_index >=0) && (neighbour_index < number_of_points)) {
                            if (output_data[neighbour_index] == 0) {
                                // Add this point to the set (with a suggested position which speeds up the addition).
                                
                                new_set_of_points.insert(new_set_of_points.begin(), neighbour_index);
                            }
                        }
                    }
                }                
            }
        }
        
        iteration_number++;
        if (iteration_number > max_iterations) {
            if (max_iter_set_manually) {
                mexWarnMsgTxt("Terminating as the specified maximum iteration number has been reached");
                mxFree(neighbour_counts);    
                return;
            } else {
                mxFree(neighbour_counts);    
                mexErrMsgTxt("Error: Maximum number of iterations has been exceeded");
            }
        }        
        
    }
    
    mexPrintf("-Ending after %i iterations and freeing memory\n", iteration_number);
    mxFree(neighbour_counts);    
    
}





// The main function call
void mexFunction(int num_outputs, mxArray* pointers_to_outputs[], int num_inputs, const mxArray* pointers_to_inputs[])
{
    mexPrintf("PTKSmoothedRegionGrowingFromBorderedImage\n");
    
    // Check inputs
    if ((num_inputs < 2) || (num_inputs > 3)) {
        mexErrMsgTxt("Two inputs are required: the labeled input image and the structural element to use for smoothing. The third optional input is the maximum number of iterations");
    }
    
    if (num_outputs > 1) {
        mexErrMsgTxt("PTKSmoothedRegionGrowingFromBorderedImage produces one output but you have requested more.");
    }
    
    // Get the input images
    const mxArray* labelled_input = pointers_to_inputs[0];
    const mxArray* smoothing_element = pointers_to_inputs[1];
    
    bool max_iter_set_manually = false;
    unsigned long max_iterations = 1000000000;
    if (num_inputs == 3) {
        if ((!mxIsNumeric(pointers_to_inputs[2])) || (mxGetNumberOfElements(pointers_to_inputs[2]) != 1) || mxIsComplex(pointers_to_inputs[2])) {
            mexErrMsgTxt("The maximum number of iterations must be noncomplex integer.");
        }
        max_iterations = mxGetScalar(pointers_to_inputs[2]);
        max_iter_set_manually = true;
    }
    
    Size dimensions = GetDimensions(labelled_input);
    Size dimensions_smoothing_element = GetDimensions(smoothing_element);
    
    if (mxGetClassID(labelled_input) != mxINT8_CLASS || mxIsComplex(labelled_input)) {
        mexErrMsgTxt("Labelled input image must be noncomplex int8.");
    }
    
    if (mxGetClassID(smoothing_element) != mxINT8_CLASS || mxIsComplex(smoothing_element)) {
        mexErrMsgTxt("Smoothing element must be noncomplex int8.");
    }
    
    // Create mxArray for the output data
    mxArray* output_array = mxCreateNumericArray(3, dimensions.size, mxINT8_CLASS, mxREAL);
    pointers_to_outputs[0] = output_array;
    
    LabelledInputType* labelled_input_data = (LabelledInputType*)mxGetData(labelled_input);
    SmoothingElementType* smoothing_element_data = (SmoothingElementType*)mxGetData(smoothing_element);
    
    // Get the dimensions of the input matrices
    SizeVector labelled_image_size(3);
    labelled_image_size[0] = dimensions.size[0];
    labelled_image_size[1] = dimensions.size[1];
    labelled_image_size[2] = dimensions.size[2];
    
    SizeVector smoothing_element_size(3);
    smoothing_element_size[0] = dimensions_smoothing_element.size[0];
    smoothing_element_size[1] = dimensions_smoothing_element.size[1];
    smoothing_element_size[2] = dimensions_smoothing_element.size[2];
    
    PointType number_of_points = labelled_image_size[0]*labelled_image_size[1]*labelled_image_size[2];
    
    // Initialise the output data
    OutputType* output_data = (OutputType*)mxGetData(pointers_to_outputs[0]);
    for (PointType point_index = 0; point_index < number_of_points; point_index++) {
        LabelledInputType input_value = labelled_input_data[point_index];
        output_data[point_index] = input_value;            
    }
    
    // Run the loop
    SmoothedRegionGrowing(labelled_input_data, smoothing_element_data, output_data, max_iterations, labelled_image_size, smoothing_element_size, max_iter_set_manually);
    
    mexPrintf(" - Completed PTKSmoothedRegionGrowingFromBorderedImage\n");
    return;
}