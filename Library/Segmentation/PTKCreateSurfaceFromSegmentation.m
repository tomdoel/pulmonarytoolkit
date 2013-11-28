function [fv, normals] = PTKCreateSurfaceFromSegmentation(segmentation, smoothing_size, small_structures, label, coordinate_system, template_image, reporting)
    % PTKCreateSurfaceFromSegmentation. Creates a surface mesh from a segmentation volume.
    %
    %     Inputs
    %     ------
    %
    %     filepath, filename - path and filename for STL file
    %
    %     segmentation - a binary 3D PTKImage containing 1s for the voxels to
    %         visualise
    %
    %     smoothing_size - the amount of smoothing to perform. Higher
    %         smoothing makes the image look better but removes small
    %         structures such as airways and vessels
    %
    %     small_structures - set to true for improved visualisation of
    %         narrow structures such as airways and vessels
    %
    %     label - Only voxels of this colour are considered
    %
    %     coordinate_system  a PTKCoordinateSystem enumeration
    %         specifying the coordinate system to use
    %
    %     template_image  A PTKImage providing voxel size and image size
    %         parameters, which may be required depending on the coordinate
    %         system
    %
    %     reporting - a PTKReporting object for progress, warning and
    %         error reporting.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    if ~isa(segmentation, 'PTKImage')
        error('Requires a PTKImage as input');
    end
    
    % Isolate this colour component
    sub_seg = segmentation.BlankCopy;
    sub_seg.ChangeRawImage(segmentation.RawImage == label);
    
    % Perform a closing operation and filter the image to create a smoother appearance
    if small_structures
        morph_size = 1;
    else
        morph_size = 3;
    end
    
    if morph_size > 0
        sub_seg.BinaryMorph(@imclose, morph_size);
    end
    
    if smoothing_size > 0
        sub_seg = PTKGaussianFilter(sub_seg, smoothing_size);
    end
    
    % Draw the 3D surface
    if small_structures
        threshold = 0.2;
    else
        threshold = 0.5;
    end
    
    [xc, yc, zc] = sub_seg.GetPTKCoordinates;
    [xc, yc, zc] = PTKImageCoordinateUtilities.ConvertFromPTKCoordinatesCoordwise(xc, yc, zc, coordinate_system, template_image);
    
    fv = isosurface(xc, yc, zc, sub_seg.RawImage, threshold);
    
    if nargout > 1
        normals = isonormals(xc, yc, zc, sub_seg.RawImage, fv.vertices);
    end
end