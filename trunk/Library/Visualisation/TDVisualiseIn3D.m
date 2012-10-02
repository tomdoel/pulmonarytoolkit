function figure_handle = TDVisualiseIn3D(figure_handle, segmentation, smoothing_size, small_structures, reporting)
    % TDVisualiseIn3D. Opens a new Matlab figure and visualises the
    % segmentation image in 3D.
    %
    %
    %     Inputs
    %     ------
    %
    %     figure_handle - specify an empty array [] to open a new figure, or the
    %         handle of the existing figure for the visualisation
    %
    %     segmentation - a binary 3D TDImage containing 1s for the voxels to
    %         visualise
    %
    %     smoothing_size - the amount of smoothing to perform. Higher
    %         smoothing makes the image look better but removes small
    %         structures such as airways and vessels
    %
    %     small_structures - set to true for improved visualisation of
    %         narrow structures such as airways and vessels
    %
    %     reporting - a TDReporting object for progress, warning and
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
    
    
    if ~isa(segmentation, 'TDImage')
        error('Requires a TDImage as input');
    end
    
    if nargin < 2
        smoothing_size = 4; % A good value for lobes
    end
    
    if nargin < 3
        reporting = TDReportingDefault;    
    end
    
    if isempty(figure_handle)
        figure_handle = figure;
    else
        figure(figure_handle);
    end
    
    if small_structures
        smoothing_size = 1;
    end
    
    reporting.ShowProgress('Generating the 3D image');
    
    % Crop surrounding whitespace and reduce the image size if it is large.
    % A smaller image size is necessary for the use of isonormals
    segmentation.CropToFit;
    segmentation.RescaleToMaxSize(200);
    segmentation.AddBorder(1);
    
    % Determine the aspect ratio of the 3D image
    voxel_size = segmentation.VoxelSize;
    aspect_ratio = [1/voxel_size(2), 1/voxel_size(1), 1/voxel_size(3)];

    % Set up appropriate figure properties
    figure;
    axis off;
    axis square;
    lighting gouraud;
    axis equal;
    set(gcf, 'Color', 'white');
    daspect(aspect_ratio);
    rotate3d;
    cm = colormap('Lines');
    view(-37.5, 30);
    camlight('headlight');
        
    % Get a list of all labels in the segmentation image
    segmentation_labels = setdiff(unique(segmentation.RawImage(:)), 0);
    
    number_of_segmentations = length(segmentation_labels);
    
    % Separate the segmentation into components; one for each colour.
    % Iterate through these components and draw each separately
    for label_index = 1 : number_of_segmentations
        
        label = segmentation_labels(label_index);
        reporting.CheckForCancel;
        reporting.UpdateProgressValue(100*(label_index-1)/number_of_segmentations);
        
        % Isolate this colour component
        sub_seg = segmentation.BlankCopy;
        sub_seg.ChangeRawImage(segmentation.RawImage == label);
        
        % Perform a closing operation and filter the image to create a smoother appearance
        if small_structures
            morph_size = 1;
        else
            morph_size = 3;
        end
        
        sub_seg.BinaryMorph(@imclose, morph_size);
        
        if smoothing_size > 0
            sub_seg = TDGaussianFilter(sub_seg, smoothing_size);
        end
        
        % Get the colour from the colourmap
        this_colour = (mod(label-1, 60)) + 1;
        cm_color = cm(this_colour, :);
        
        % Draw the 3D surface
        if small_structures
            threshold = 0.2;
        else
             threshold = 0.5;
        end
        p = patch(isosurface(sub_seg.GetRawImageForPlotting, threshold), 'EdgeColor', 'none', 'FaceColor', cm_color);
        
        % Using isonormals improves the image quality but is slow for large
        % images
        isonormals(sub_seg.GetRawImageForPlotting, p);

    end
    camorbit(0, -25);
    camorbit(25, 0);

    reporting.UpdateProgressValue(100);
    
end