function segmentation = TDGetSurfaceFromSegmentation(segmentation)
    % TDGetSurfaceFromSegmentation. Finds the surface of a segmented 3D binary volume.
    %
    % The input and output images are raw image matrices containing a mask of 0s
    % and 1s where 1 is a segmented voxel.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    
    segmentation = int8(segmentation == 1);

    % Find voxels that are nonzero and do not have 6 nonzero neighbours
    filter = zeros(3, 3, 3);
    filter(:) = [0 0 0 0 1 0 0 0 0 0 1 0 1 0 1 0 1 0 0 0 0 0 1 0 0 0 0];
    image_conv = convn(segmentation, filter, 'same');
    segmentation = (segmentation & (image_conv < 6));
end