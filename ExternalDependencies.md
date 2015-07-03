# Introduction #

This page describes how the Pulmonary Toolkit depends on external software. We aim to remove these dependencies where possible.

This is not yet a complete and definitive list.

# Matlab Image Processing Toolbox #

I would like to remove this dependency. However, several important functions are used that will require reprogramming. These are based on standard published algorithms, so implementation is straightforward but will require time.

The following functions are used
  * imshow - for initial creation of the image axes. Should be able to remove this
  * dicomread / dicomwrite / dicominfo / dicomuid - for reading and writing DICOM files. Will need to implement new or include external open-source code to remove this dependency
  * label2rgb - For displaying TDImage.Colormap images (e.g. colour overlays). Writing a replacement function should be straightforward
  * imclose, imdilate, imerode, imopen, strel - Morphological operations - widely used. Need to be replaced with fast C++ code
  * bwconncomp - connected component analysis - widely used. Needs to be replaced with fast C++ code.

# ITK #

Currently the code does not depend on ITK, but ITK is built as part of the gerardus build procedure. Remove this dependency by modifying the build procedure

# boost #

Required by the mba line fitting code. The open source allows us to include the files in our project. I believe the required files are all header files so we can add them to the project and include them as part of the build procedure.

# C++ compiler #

Required to compile a number of mex functions used by the project

# gerardus #

We use the mba fitting code. The open-source licence allows us to include the relevant files in our project so we can add these and include them in our build procedure.