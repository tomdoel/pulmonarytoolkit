function output_image = PTKSmoothedRegionGrowing(threshold_image, start_points_global, smoothing_size_mm, reporting)
    % PTKSmoothedRegionGrowing. Performs 3D region growing through the supplied
    %     binary threshold image, starting from the specified points
    %
    %
    %     Syntax:
    %         output_image = PTKSmoothedRegionGrowing(threshold_image, start_points_global, reporting)
    %
    %         Inputs:
    %         ------
    %             threshold_image - The threshold image in a PTKImage class. 1s
    %                 represents voxels which are connected
    %             start_points - an set of starting points, where each element
    %                 in the set is array of points representing one region.
    %                 Each point is a global index. The region growing will 
    %                 begin from all these points simultaneously
    %             smoothing_size_mm - amoung of smoothing. A larger value will
    %                 give better results but will be slower
    %             reporting - a PTKReporting object for progress, warning and
    %                 error reporting.
    %
    %         Outputs:
    %         -------
    %             output_image - A binary PTKImage containing the segmented region
    %                 of all voxels connected to the starting points
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    % Check the input image is of the correct form
    if ~isa(threshold_image, 'PTKImage')
        error('Requires a PTKImage as input');
    end
    
    if exist('reporting', 'var')
        reporting.ShowProgress('Smoothed region growing');
    end
    
    max_number_of_iterations = 1000;
    
    threshold_image_resized = threshold_image.Copy;
    threshold_image_resized.CropToFit;
    
    % Create a spherical structural element
    ball = int8(PTKImageUtilities.CreateBallStructuralElement(threshold_image_resized.VoxelSize, smoothing_size_mm));
    ball_im = PTKImage(ball, PTKImageType.Colormap, threshold_image_resized.VoxelSize);
    ball_im.CropToFit;
    ball_raw = ball_im.RawImage;
    
    % Add a border around the image of size one less than the structural element
    % size. We do this to avoid having to consider bounday conditions, which
    % speeds up the calculation
    border_size = ball_im.ImageSize - 1;
    threshold_image_resized.AddBorder(border_size);
    
    % Set up the initial input image with -1 for voxels outside the mask, 0 for
    % voxels in the mask and positive values for each label
    input_image_raw = -1*ones(threshold_image_resized.ImageSize, 'int8');
    input_image_raw(threshold_image_resized.RawImage) = 0;    
    number_of_regions = length(start_points_global);
    for region_index = 1 : number_of_regions
        start_points_for_this_index = start_points_global{region_index};
        points_index_local = threshold_image_resized.GlobalToLocalIndices(start_points_for_this_index);
        input_image_raw(points_index_local) = region_index;
    end
    
    output_raw = PTKSmoothedRegionGrowingFromBorderedImage(input_image_raw, ball_raw, max_number_of_iterations);
    output_raw(output_raw == -1) = 0;
    
    output_image = threshold_image_resized.BlankCopy;
    output_image.ChangeRawImage(output_raw);
    output_image.ResizeToMatch(threshold_image);
end