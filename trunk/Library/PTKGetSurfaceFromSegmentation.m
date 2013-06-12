function segmentation = PTKGetSurfaceFromSegmentation(segmentation, exclude_direction)
    % PTKGetSurfaceFromSegmentation. Finds the surface of a segmented 3D binary volume.
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
    
    if nargin < 2
        exclude_direction = [];
    end
    
    segmentation = int8(segmentation > 0);

    % Find voxels that are nonzero and do not have 6 nonzero neighbours
    filter = zeros(3, 3, 3);
    if isempty(exclude_direction)
        filter(:) = [0 0 0 0 1 0 0 0 0 0 1 0 1 0 1 0 1 0 0 0 0 0 1 0 0 0 0];
    elseif exclude_direction == PTKImageOrientation.Coronal
        filter(:) = [0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0];
    else
        error('PTKGetSurfaceFromSegmentation:UnsupportedExcludeDirection', 'Unsupported exclude direction');
    end
    max_neighbours = sum(filter(:));
    image_conv = convn(segmentation, filter, 'same');
    segmentation = (segmentation & (image_conv < max_neighbours));
end