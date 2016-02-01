# DicoMat
DicoMat is Matlab software for reading Dicom files and grouping into 3D image volumes.

## DICOM file reading
DicoMat provides Dicom file reading functions that are faster than the Matlab versions, and do not require the Matlab Image Processing Toolbox.

 * DMisdicom - tests if a file appears to be a DICOM file
 * DMdicominfo - loads DICOM tags from a file and returns them as a MATLAB struct
 * DMdicomread- reads DICOM pixel data from a file
 
Please note: while these functions are used in a similar way to the corresponding methods of the Matlab Image Processing Toolbox, they are not guaranteed to return the exact same output in all circumstances. DicoMat may not work for all DICOM files.

## DICOM series export

DicoMat can write out an original or secondary capture series. This may require the Matlab Image Processing Toolbox.

## DICOM file grouping

In the simplest form, the following function can be used to load the largest series from a directory structure of DICOM images.
The function will recursively search the supplied folder and its subdirectories for DICOM images, and then group them according to DICOM tags and geometry.
If this results in more than one group of images, the largest group will be returned.

imageWrapper = DMFindAndLoadMainImageFromDicomFiles(rootFolder)
