function labeled_subregion_mask = PTKVoronoiDivision(region_mask, start_points, reporting)
    % PTKVoronoiDivision. Allocates voxels in an image region to the nearest label
    %
    %     PTKVoronoiDivision takes an image region defined by the boolean image 
    %         region_mask. The region is subdivided into subregions, by grouping
    %         voxels according to the nearest point in start_points. Each
    %         subregion is allocated the colour of its corresponding
    %         start_point. The output image is therefore a label matrix.
    
    %         The input start_points can either be a labelled PTKImage, with
    %         positive values representing start points. Voxels of value 1 will
    %         be used to define subregion 1, those of value 2 will define
    %         subregion 2 etc. 
    %
    %         Alternatively, start_points can be a set of
    %         regions, each member of which is a vector of start points for that
    %         region. Each start point is defined by its global index.
    %         So if start_points == {[1, 3, 5], [490, 138]}, then the first set
    %         member [1,3,5] represents points with label 1, and the second set
    %         member [490, 138] represets points with label 2. There are five
    %         start points altogether, and each is defined by its global index.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
     
    if ~isa(region_mask, 'PTKImage')
        reporting.Error('PTKVoronoiDivision:BadInput', 'Requires a PTKImage as input');
    end
    
    if ~isa(start_points, 'PTKImage')
        if iscell(start_points)
            start_points = PTKPointListToLabelMatrix(start_points, region_mask, reporting);
        else
           reporting.Error('PTKVoronoiDivision:BadInput', 'start_points must be either a cell array or a PTKImage.');
        end
    end
    
    % Make a copy of the region image before resizing
    output_template = region_mask.BlankCopy;
    
    % First, make copies of the inputs since this could modify them
    start_points = start_points.Copy;
    region_mask = region_mask.Copy;
    
    % Now crop to the minimal sizes and then match the sizes
    region_mask.CropToFit;
    start_points.CropToFit;
    PTKImageUtilities.MatchSizesAndOrigin(start_points, region_mask);
    
    % Use the DT function to find the nearest neighbours
    [~, nn_indicies] = bwdist(start_points.RawImage > 0);
    
    % Label each voxel by the index of its nearest neighbour
    results_image_raw = start_points.RawImage(nn_indicies);
    
    % Store results
    labeled_subregion_mask = region_mask.BlankCopy;
    labeled_subregion_mask.ChangeRawImage(results_image_raw); 
    
    % Resize to match original input size
   labeled_subregion_mask.ResizeToMatch(output_template);
end