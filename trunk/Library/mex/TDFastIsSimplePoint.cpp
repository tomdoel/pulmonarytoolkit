// TDFastIsSimplePoint. Function for determining if a point is topologically simple.
//
//     This is a Matlab MEX function and must be compled before use. To compile, type 
//
//         mex TDFastIsSimplePoint
//
//     on the Matlab command line.
//
//     This is an optimised adaption of the algorithm by G Malandain, G Bertrand, 1992
//
//     Alternatively, you can use the Matlab-only implementation TDIsSimplePoint 
//     which is equivalent to this function but slower as it does not use mex files. 
//
//     Syntax
//     ------
//         is_simple = TDFastIsSimplePoint(image)
//
//     Input
//     -----
//         image - a 3x3x3 int8 matrix representing the point and its neighbourhood (1 = point, 0 = no point)
//
//     Output
//     ------
//         is_simple - true if the point is topologically simple
// 
// 
//     
//     This function is used in skeletonisation to determine whether points are 
//     simple and therefore can be removed as part of the skeletonisation process
//
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
         
    if (number_of_dimensions != 3) {
        mexErrMsgTxt("The input matricx must have 3 dimensions.");
    }
             
    dimensions.size[0] = array_dimensions[0];
    dimensions.size[1] = array_dimensions[1];
    dimensions.size[2] = 1;
    if (number_of_dimensions > 2) {
        dimensions.size[2] = array_dimensions[2];
    }
    
    return dimensions;
};

bool IsConnected(char* image, const int& n) {
    
    // Initialisation
    
    char Nconnect[125];
    char Nvisit[125];
    set<char> neighbour_offsets;
    
    if (n == 6) {
        char neighbour_offsets6[] = {25, -25, 5, -5, 1, -1};
        
        for (int index = 0; index <= 5; index++) {
            neighbour_offsets.insert(neighbour_offsets6[index]);
        }
        
        char Nconnect6[] = {
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,1,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,0,1,0,0,
            0,1,0,1,0,
            0,0,1,0,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,1,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0
        };
        
        char Nvisit6[]   = {
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,0,1,0,0,
            0,1,1,1,0,
            0,0,1,0,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,1,1,1,0,
            0,1,0,1,0,
            0,1,1,1,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,0,1,0,0,
            0,1,1,1,0,
            0,0,1,0,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0
        };
        
        for (int index = 0; index < 125; index++) {
            Nconnect[index] = Nconnect6[index];
            Nvisit[index] = Nvisit6[index];
        }
        
    } else {
        char neighbour_offsets26[] = {-31, -30, -29, -6, -5, -4, 19, 20, 21, -26, -25, -24, -1,  1, 24, 25, 26, -21, -20, -19,  4,  5,  6, 29, 30, 31};
        
        for (int index = 0; index < 26; index++) {
            neighbour_offsets.insert(neighbour_offsets26[index]);
        }
        
        char Nconnect26[] = {
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,1,1,1,0,
            0,1,1,1,0,
            0,1,1,1,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,1,1,1,0,
            0,1,0,1,0,
            0,1,1,1,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,1,1,1,0,
            0,1,1,1,0,
            0,1,1,1,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0
        };

        for (int index = 0; index < 125; index++) {
            Nconnect[index] = Nconnect26[index];
            Nvisit[index] = Nconnect26[index];
        }
    }
    
    // Points-to-connect are the points which must have been visited by the end of the algorithm for this to be a simple point
    char points_to_connect[125];
    
    // Points-that-can-be-visited are points which can be travsersed when connecting the points-to-connect
    char points_that_can_be_visited[125];
    
    // Initialise these arrays
    for (int index = 0; index < 125; index++) {
        points_to_connect[index] = Nconnect[index] && image[index];
        points_that_can_be_visited[index] = Nvisit[index] && image[index];
    }
    
    // Find first point
    char index_of_first_point_to_connect = 31; // 31 is the first point inside the border
    while (points_to_connect[index_of_first_point_to_connect] == 0) {
        index_of_first_point_to_connect++;
        if (index_of_first_point_to_connect >= 125) {
            return false;
        }
    }
    
    // Mark the first point as already visited
    points_that_can_be_visited[index_of_first_point_to_connect] = 0;
    points_to_connect[index_of_first_point_to_connect] = 0;
    
    // Create the set of points-to-do
    set<char> S;
    S.insert(index_of_first_point_to_connect);
    
    // Iterate through the points-to-do
    while (!S.empty()) {
        set<char>::iterator next_point = S.begin();
        char y = *next_point;
        S.erase(next_point);
        
        // Find neighbours of this point
        for (set<char>::iterator iter = neighbour_offsets.begin(); iter != neighbour_offsets.end(); iter++) {
            char z = y + *iter;
            if (points_that_can_be_visited[z]) {
                
                // Found a valid neighbour - mark as visited and add to the set of points-to-do
                points_that_can_be_visited[z] = 0;
                S.insert(z);
            }
        }
    }
    
    // Return true if all the points-to-connect have been visited
    for (char index = 0; index < 125; index++) {
        if (points_to_connect[index] && points_that_can_be_visited[index]) {
            return false;
        }
    }
    return true;
}


// The main function call
void mexFunction(int num_outputs, mxArray* pointers_to_outputs[], int num_inputs, const mxArray* pointers_to_inputs[])
{    
    // Check inputs
    if (num_inputs != 1) {
        mexErrMsgTxt("Usage: is_simple = TDIsSimplePoint(image) where image is a 3x3x3 int8 matrix of the neighbourhood around the point.");
    }
    
    if (num_outputs > 1) {
         mexErrMsgTxt("TDIsSimplePoint produces one output but you have requested more.");
    }
    
    // Get the input image
    const mxArray* input_image = pointers_to_inputs[0];
    
    Size dimensions = GetDimensions(input_image);
    if (dimensions.size[0] != 3 || dimensions.size[1] != 3 || dimensions.size[2] != 3) {
        mexErrMsgTxt("The input image must be of size 3x3x3.");
    }
    
    if (mxGetClassID(input_image) != mxINT8_CLASS || mxIsComplex(input_image)) {
        mexErrMsgTxt("the input variable must be an int8 matrix.");
    }
    
    mxLogical result = 0;
    
    // Create mxArray for the output data    
    mxArray* output_array = mxCreateLogicalMatrix(1,1);
    pointers_to_outputs[0] = output_array;
    mxLogical* function_result = mxGetLogicals(output_array);
        
    char* image_data = (char*)mxGetData(input_image);
    
    char image_bordered[125];
    char image_reversed[125];
    
    char image_indices[] = {
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,1,2,3,0,
            0,4,5,6,0,
            0,7,8,9,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,10,11,12,0,
            0,13,14,15,0,
            0,16,17,18,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,19,20,21,0,
            0,22,23,24,0,
            0,25,26,27,0,
            0,0,0,0,0,
            
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0,
            0,0,0,0,0
        };

    
    
    for (int index = 0; index < 125; index++) {
        char image_index = image_indices[index];
        if (image_index > 0) {
            char data_binary = image_data[image_index - 1] > 0 ? 1 : 0;
            image_bordered[index] = data_binary;
            image_reversed[index] = 1 - data_binary;
        } else {
            image_bordered[index] = 0;
            image_reversed[index] = 0;
        }
    }
    
    result = IsConnected(image_bordered, 26) && IsConnected(image_reversed, 6);
    
    function_result[0] = result;

    return;
}
