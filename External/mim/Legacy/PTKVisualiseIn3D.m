function axes_handle = PTKVisualiseIn3D(axes_handle, segmentation, smoothing_size, small_structures, reporting)
    % PTKVisualiseIn3D. Opens a new Matlab figure and visualises the
    % segmentation image in 3D.
    %
    %
    %     Inputs
    %     ------
    %
    %     axes_handle - specify an empty array [] to open a new figure, or the
    %         axes_handle of the existing axes for the visualisation
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
    %     reporting - an object implementing CoreReportingInterface
    %         for reporting progress and warnings
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    if nargin < 3
        smoothing_size = 4; % A good value for lobes
    end

    if nargin < 4
        small_structures = false;
    end
    
    if nargin < 5
        reporting = CoreReportingDefault();    
    end
    
    limit_to_one_component_per_index = false;
    minimum_component_volume_mm3 = 0;
    surface_colormap = CoreSystemUtilities.BackwardsCompatibilityColormap();
    
    axes_handle = MimVisualiseIn3D(axes_handle, segmentation, smoothing_size, small_structures, limit_to_one_component_per_index, minimum_component_volume_mm3, surface_colormap, reporting);
end