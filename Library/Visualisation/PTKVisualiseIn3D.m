function figure_handle = PTKVisualiseIn3D(figure_handle, segmentation, smoothing_size, small_structures, reporting)
    % PTKVisualiseIn3D. Opens a new Matlab figure and visualises the
    % segmentation image in 3D.
    %
    %
    %     Inputs
    %     ------
    %
    %     figure_handle - specify an empty array [] to open a new figure, or the
    %         handle of the existing figure for the visualisation
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
    
    if isempty(figure_handle)
        figure_handle = figure;
    else
        figure(figure_handle);
    end
    
    if small_structures
        smoothing_size = min(1, smoothing_size);
    end
    
    reporting.ShowProgress('Generating the 3D image');
    
    % Crop surrounding whitespace and reduce the image size if it is large.
    % A smaller image size is necessary for the use of isonormals
    segmentation = segmentation.Copy;
    segmentation.CropToFit;
    
    % Speed up visualisation by rescaling large images.
    if ~small_structures
        segmentation.RescaleToMaxSize(200);
    end
    
    segmentation.AddBorder(1);
    
    % Set up appropriate figure properties
    axis off;
    axis square;
    lighting gouraud;
    axis equal;
    set(gcf, 'Color', 'white');

    % Fix data aspect ratio. Note this is not set from the voxel size, because
    % we are drawing the image using coordinates in mm, which already take the
    % voxel size into account
    daspect([1 1 1]);
    
    rotate3d;
    cm = colormap('Lines');
    view(-37.5, 30);
    
    % Change camera angle
    campos([0, -1600, 0]);
    
    % Get a list of all labels in the segmentation image
    raw_image = segmentation.GetMappedRawImage;
    segmentation_labels = setdiff(unique(raw_image(:)), 0);
    
    number_of_segmentations = length(segmentation_labels);
    
    % We choose the PTK coordinate system, which requires no image template
    coordinate_system = PTKCoordinateSystem.PTK;
    template_image = [];

    ambient_strength =0.4;
    diffuse_strength = 0.7;
    specular_strength = 1;    
    
    % Separate the segmentation into components; one for each colour.
    % Iterate through these components and draw each separately
    for label_index = 1 : number_of_segmentations
        
        label = segmentation_labels(label_index);
        reporting.CheckForCancel;
        reporting.UpdateProgressValue(100*(label_index-1)/number_of_segmentations);
        
        % Get the colour from the colourmap
        this_colour = (mod(label-1, 60)) + 1;
        cm_color = cm(this_colour, :);

        [fv, normals] = PTKCreateSurfaceFromSegmentation(segmentation, smoothing_size, small_structures, label, coordinate_system, template_image, reporting);
        
        p = patch(fv, 'EdgeColor', 'none', 'FaceColor', cm_color, 'AmbientStrength', ambient_strength, 'SpecularStrength', specular_strength, 'DiffuseStrength', diffuse_strength);
        
        % Using isonormals improves the image quality but is slow for large
        % images
        set(p, 'VertexNormals', normals);

    end
    
    % Add lighting
    cl = camlight('left');
    set(cl, 'Position', [400, 500, -50]);

    reporting.UpdateProgressValue(100);
    reporting.CompleteProgress;
end