function [fv, normals] = PTKCreateSurfaceFromSegmentation(segmentation, smoothing_size, small_structures, label)
    % PTKCreateSurfaceFromSegmentation. Creates a surface mesh from a segmentation volume.
    %
    %
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
    
    [xc, yc, zc] = sub_seg.GetCornerGlobalCoordinatesMm;
    
    fv = isosurface(xc, yc, zc, sub_seg.RawImage, threshold);
    
    if nargout > 1
        normals = isonormals(xc, yc, zc, sub_seg.RawImage, fv.vertices);
    end
end