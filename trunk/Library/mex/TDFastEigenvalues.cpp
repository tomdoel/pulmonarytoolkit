// TDFastEigenvalues. Computes eigenvalues and eigenvectors for many symmetric matrices
//
//     TDFastEigenvalues is similar to Matlab's eigs() function, but can be used 
//     to compute the eigenvalues and eigenvectors for multiple matrices, which
//     for a large number of points is significantly quicker than using a for 
//     loop. Each input matrix must be symmetric and is represented by a single
//     row of the input matrix as described below.
//
//     This is a Matlab MEX function and must be compled before use. To compile, type 
//
//         mex TDFastEigenvalues
//
//     on the Matlab command line.
//
//     Alternatively, you can use the Matlab function TDVectorisedEigenvalues 
//     which is equivalent to this function but does not use mex files. 
//     TDVectorisedEigenvalues is slower than TDFastEigenvalues but still
//     significantly faster than running eigs() in a for loop when a large
//     number of matrices is involved.
//
//
//     Syntax: 
//         [eigvectors, eigvalues] = TDFastEigenvalues(M [, eigenvalues_only])
//
//     Input:
//         M is a 6xn matrix. Each column of M represents one 3x3 symmetric matrix as follows
//
//                 [V(1) V(2) V(3); V(2) V(4) V(5); V(3) V(5) V(6)]
//
//             where V is a 6x1 column of M
//
//         eigenvalues_only is an optional parameter which defaults to false. Set to true to only calculate eigenvalues and not eigenvectors, which reduces the execution time
//
//     Outputs:
//         eigenvalues is a 3xn matrix. Each column contains the 3 eigenvalues of the matrix V described above
//         eigenvectors is a 3x3xn matrix, where each 3x1 row represents an eigenvector (3 for each of the n matrices V described above)
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
#include <math.h>
#include "mex.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Use this line to change precision to float or double
#define SINGLEPRECISION

#ifdef SINGLEPRECISION
#define PRECISION float
#define CALCPRECISION float
#define MATLABTYPE mxSINGLE_CLASS
#else
#define PRECISION double
#define CALCPRECISION double
#define MATLABTYPE mxDOUBLE_CLASS
#endif


using namespace std;

extern void _main();

struct TDVector {
    CALCPRECISION x, y, z;
	TDVector() : x(0), y(0), z(0) {}	
	TDVector(CALCPRECISION xx, CALCPRECISION yy, CALCPRECISION zz) : x(xx), y(yy), z(zz) {}
};

TDVector CrossProduct(const TDVector& v1, const TDVector& v2) {
    TDVector result;
	result.x = (v1.y * v2.z) - (v1.z * v2.y);
	result.y = (v1.z * v2.x) - (v1.x * v2.z);
	result.z = (v1.x * v2.y) - (v1.y * v2.x);
	return result;
}

typedef struct Size2 {
    mwSize size[2];
} Size2;

Size2 GetAndValidateDimensions2D(const mxArray* array) {
    Size2 dimensions;
    
    mwSize number_of_dimensions = mxGetNumberOfDimensions(array);
    const mwSize* array_dimensions = mxGetDimensions(array);
         
    if (number_of_dimensions > 2) {
        mexErrMsgTxt("The input matricies must have 2 dimensions.");
    }
             
    dimensions.size[0] = array_dimensions[0];
    dimensions.size[1] = array_dimensions[1];
    
    return dimensions;
};


// The main function call
void mexFunction(int num_outputs, mxArray* pointers_to_outputs[], int num_inputs, const mxArray* pointers_to_inputs[])
{
    // Check inputs
    if (num_inputs < 1) {
        mexErrMsgTxt("Syntax: [eigvectors, eigvalues] = TDFastEigenvalues(M) where M is a 6xn matrix representing n symmetrix 3x3 matrices (see source file for more information).\n");
    }
    
    if (num_inputs > 2) {
        mexErrMsgTxt("Too many arguments specified. Syntax: TDFastEigenvalues(M) where M represents the matricies (see source file).\n");
    }

    if (num_outputs > 2) {
         mexErrMsgTxt("TDFastEigenvalues produces two outputs but you have requested more.\n");
    }
    
	if (mxIsComplex(pointers_to_inputs[0])) {
        mexErrMsgTxt("The input matrix must be noncomplex.\n");
    }

	if (mxGetClassID(pointers_to_inputs[0]) != MATLABTYPE) {
#ifdef SINGLEPRECISION
        mexErrMsgTxt("Input image must be of single type.\n");
#else
        mexErrMsgTxt("Input image must be of double type.\n");
#endif
		
	}
		
    // Get the input data
	PRECISION* input_data = (PRECISION*)mxGetData(pointers_to_inputs[0]);
    Size2 dimensions = GetAndValidateDimensions2D(pointers_to_inputs[0]);

	long int rows_in_input_data = dimensions.size[0];
	long int num_matrices = dimensions.size[1];
    
    if (rows_in_input_data != 6) {
        mexErrMsgTxt("The input matrix must have 6 rows.\n");
    }

	
	bool compute_eigenvectors = true;
	if (num_inputs == 2) {
		if ((!mxIsLogical(pointers_to_inputs[1])) || (mxGetNumberOfElements(pointers_to_inputs[1]) != 1)) {
			mexErrMsgTxt("Second parameter must be a logical scalar.\n");
		}
		compute_eigenvectors = !mxIsLogicalScalarTrue(pointers_to_inputs[1]);
	}

	
	// 3-dimensional system; i.e. compute 3 eigenvalues
	mwSize num_dimensions = 3;


	// Create mxArray for the output eigenvalues
	mwSize eigval_size[2];
	eigval_size[0] = num_dimensions;
	eigval_size[1] = num_matrices;
	pointers_to_outputs[1] = mxCreateNumericArray(2, eigval_size, MATLABTYPE, mxREAL);
	PRECISION* eigval = (PRECISION*)mxGetData(pointers_to_outputs[1]);
	
	// Create mxArray for the output eigenvectors
	mwSize eigvec_size[3];
	if (compute_eigenvectors) {
		eigvec_size[0] = num_dimensions;
		eigvec_size[1] = num_dimensions;
	} else {
		eigvec_size[0] = 0;
		eigvec_size[1] = 0;
		eigvec_size[2] = 0;    
	}
	eigvec_size[2] = num_matrices;    
	pointers_to_outputs[0] = mxCreateNumericArray(3, eigvec_size, MATLABTYPE, mxREAL);;
	PRECISION* eigvec = (PRECISION*)mxGetData(pointers_to_outputs[0]);
	
	// Iterate over each matrix
    for (long int index = 0; index < num_matrices; index++) {
		
		// Create a pointer to the six components of the matrix for this matrix
		PRECISION* M = &input_data[index*rows_in_input_data];

		// Compute the eigenvalues
        
		CALCPRECISION m = (M[0] + M[3] + M[5])/CALCPRECISION(3);

        CALCPRECISION q =  (( M[0] - m) * (M[3] - m) * (M[5] - m) + 
            2 * M[1] * M[4] * M[2] -
            pow(M[2], 2) * (M[3] - m) -
            pow(M[4], 2) * (M[0] - m) - pow(M[1], 2) * (M[5] - m) )/CALCPRECISION(2);

        CALCPRECISION p = ( pow(M[0] - m, 2) + 2 * pow(M[1], 2) + 2 * pow(M[2], 2) +
            pow(M[3] - m, 2) + 2 * pow(M[4], 2) + pow(M[5] - m, 2) )/CALCPRECISION(6);

        CALCPRECISION acos_arg = q/pow(p, CALCPRECISION(1.5));
        if (acos_arg < -1) {
            acos_arg = -1;
        }
        CALCPRECISION phi = acos(acos_arg)/CALCPRECISION(3);

        if (phi < 0) {
            phi = phi + CALCPRECISION(M_PI)/3;
        }
        
		CALCPRECISION eigenvalues[3];
        eigenvalues[0] = m + 2*sqrt(p)*cos(phi);
        eigenvalues[1] = m - sqrt(p)*(cos(phi) + sqrt(CALCPRECISION(3))*sin(phi));
        eigenvalues[2] = m - sqrt(p)*(cos(phi) - sqrt(CALCPRECISION(3))*sin(phi));

        
		
        // Sort the eigenvalue in order of absolute value
        if (fabs(eigenvalues[2]) < fabs(eigenvalues[0])) {
			swap(eigenvalues[2], eigenvalues[0]);
        }
        if (fabs(eigenvalues[1]) < fabs(eigenvalues[0])) {
			swap(eigenvalues[1], eigenvalues[0]);
        }
        if (fabs(eigenvalues[2]) < fabs(eigenvalues[1])) {
			swap(eigenvalues[2], eigenvalues[1]);
        }
		
		
		// Store eigenvalues in output matrix
		long int base_index_output = index*num_dimensions;
		for (long int evalue_index = 0; evalue_index <= 2; evalue_index++) {
			eigval[base_index_output + evalue_index] = eigenvalues[evalue_index];
			
// 			if isinf(eigenvalues[evalue_index]) {
// 				mexPrintf("inf found at index %d evalue %d\n", index, evalue_index);
// 			}
// 			if isnan(eigenvalues[evalue_index]) {
// 				mexPrintf("NAN found at index %d evalue %d\n", index, evalue_index);
// 			}
		}
		

		// Compute eigenvectors
        if (compute_eigenvectors) {
			long int base_index_evector[3];
			base_index_evector[0] = (0 + index*num_dimensions)*num_dimensions;
			base_index_evector[1] = (1 + index*num_dimensions)*num_dimensions;
			base_index_evector[2] = (2 + index*num_dimensions)*num_dimensions;
			
			TDVector eigenvectors[3];

			// Compute first two eigenvectors
            for (long int evector_index = 0; evector_index <= 1; evector_index++) {
                CALCPRECISION A = M[0] - eigenvalues[evector_index];
                CALCPRECISION B = M[3] - eigenvalues[evector_index];
                CALCPRECISION C = M[5] - eigenvalues[evector_index];
                
                CALCPRECISION eix = ( M[1]*M[4] - B*M[2] ) * ( M[2]*M[4] - C*M[1] );
                CALCPRECISION eiy = ( M[2]*M[4] - C*M[1] ) * ( M[2]*M[1] - A*M[4] );
                CALCPRECISION eiz = ( M[1]*M[4] - B*M[2] ) * ( M[2]*M[1] - A*M[4] );
                
                CALCPRECISION vec = sqrt(eix*eix + eiy*eiy + eiz*eiz);
                
                if (vec < 0.01) {
                    vec = 0.01;
                }
				
				eigenvectors[evector_index] = TDVector(eix/vec, eiy/vec, eiz/vec);               
            }
            
			// Calculate third eigenvector through cross product of first two eigenvectors
            eigenvectors[2] = CrossProduct(eigenvectors[0], eigenvectors[1]);

			// Store eigenvectors in output matrix
			for (long int evector_index = 0; evector_index <= 2; evector_index++) {
				eigvec[base_index_evector[evector_index] + 0] = eigenvectors[evector_index].x;
				eigvec[base_index_evector[evector_index] + 1] = eigenvectors[evector_index].y;
				eigvec[base_index_evector[evector_index] + 2] = eigenvectors[evector_index].z;
			}
        }
    }

    return;
}