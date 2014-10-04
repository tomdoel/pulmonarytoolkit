function PTKCreateSurfaceMesh(filepath, filename, segmentation, smoothing_size, small_structures, coordinate_system, template_image, reporting)
    % PTKCreateSurfaceMesh. Creates a surface mesh from a segmentation and
    %     writes into an STL file
    %
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
    %    coordinate_system  a PTKCoordinateSystem enumeration
    %        specifying the coordinate system to use
    %
    %    template_image  A PTKImage providing voxel size and image size
    %        parameters, which may be required depending on the coordinate
    %        system
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
    
    if nargin < 2
        smoothing_size = 4; % A good value for lobes
    end
    
    if nargin < 3
        reporting = PTKReportingDefault;    
    end
        
    reporting.ShowProgress('Generating the surface mesh');

    if small_structures
        smoothing_size = min(1, smoothing_size);
    end
    
    
    % Crop surrounding whitespace and reduce the image size if it is large.
    % A smaller image size is necessary for the use of isonormals
    segmentation = segmentation.Copy;
    segmentation.CropToFit;
    
    % Speed up visualisation by rescaling large images.
    if ~small_structures
        segmentation.RescaleToMaxSize(200);
    end
    
    segmentation.AddBorder(1);
    

    % Get a list of all labels in the segmentation image
    segmentation_labels = setdiff(unique(segmentation.RawImage(:)), 0);
    
    number_of_segmentations = length(segmentation_labels);
    
    % Separate the segmentation into components; one for each colour.
    % Iterate through these components and draw each separately
    for label_index = 1 : number_of_segmentations
        
        label = segmentation_labels(label_index);
        reporting.CheckForCancel;
        reporting.UpdateProgressValue(100*(label_index-1)/number_of_segmentations);
        
        limit_to_one_component_per_index = true;
        minimum_component_volume_mm3 = 0;
        [fv, ~] = PTKCreateSurfaceFromSegmentation(segmentation, smoothing_size, small_structures, label, coordinate_system, template_image, limit_to_one_component_per_index, minimum_component_volume_mm3, reporting);
        
        current_filename = filename;
        stlwrite(fullfile(filepath, current_filename), fv);
    end
    
    reporting.UpdateProgressValue(100);
    reporting.CompleteProgress;
end