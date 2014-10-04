function [fv, normals] = PTKCreateSurfaceFromSegmentation(segmentation, smoothing_size, small_structures, label, coordinate_system, template_image, limit_to_one_component_per_index, minimum_component_volume_mm3, reporting)
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
    %     limit_to_one_component_per_index - set this flag to true if each colour
    %         index in the image represents only a single, large object.
    %         This will prevent the appearance of orphaned 'island' components caused by the
    %         image smoothing and surface rendering approximations.
    % 
    %     minimum_component_volume_mm3 - if two or more separate components in the
    %         image could share the same colour index, but you want to prevent the
    %         appearance of orphaned 'island' components caused by the
    %         image smoothing and surface rendering approximations, then set this to
    %         an appropriate minimum volume value. Any components smaller than this
    %         value will not be rendered.
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
    raw_image = segmentation.GetMappedRawImage;
    sub_seg.ChangeRawImage(raw_image == label);
    
    sub_seg.CropToFit;
    
    
    % Perform a closing operation and filter the image to create a smoother appearance
    if small_structures
        morph_size = 1;
        threshold = 0.2;
    else
        morph_size = 3;
        threshold = 0.5;
    end

    required_padding_mm = 2*threshold + morph_size;
    required_padding = ceil(required_padding_mm/min(segmentation.VoxelSize)) + 1;
    sub_seg.AddBorder(required_padding);
    
    if morph_size > 0
        sub_seg.BinaryMorph(@imclose, morph_size);
    end
    
    if smoothing_size > 0
        sub_seg = PTKGaussianFilter(sub_seg, smoothing_size);
    end
    
    if limit_to_one_component_per_index
        
        % The smoothing may split the segmentation, so we consider only the main component,
        % and remove any other components by setting their value to zero
        surviving_components = sub_seg.RawImage >= threshold;
        surviving_components = xor(surviving_components, PTKImageUtilities.GetLargestConnectedComponent(surviving_components));
    else

        cc = bwconncomp(sub_seg.RawImage >= threshold);
        num_pixels = cellfun(@numel, cc.PixelIdxList);
        voxel_threshold = minimum_component_volume_mm3/prod(segmentation.VoxelSize);
        larger_elements = num_pixels > voxel_threshold;
        surviving_components = false(sub_seg.ImageSize);
        for index = 1 : numel(larger_elements)
            if larger_elements(index)
                surviving_components(cc.PixelIdxList{index}) = true;
            end
        end
    end
    
    sub_seg_raw = sub_seg.RawImage;
    sub_seg_raw(~surviving_components) = 0;
    sub_seg.ChangeRawImage(sub_seg_raw);
    
    [xc, yc, zc] = sub_seg.GetPTKCoordinates;
    [xc, yc, zc] = PTKImageCoordinateUtilities.ConvertFromPTKCoordinatesCoordwise(xc, yc, zc, coordinate_system, template_image);
    
    fv = isosurface(xc, yc, zc, sub_seg.RawImage, threshold);
    
    if nargout > 1
        normals = isonormals(xc, yc, zc, sub_seg.RawImage, fv.vertices);
    end
end