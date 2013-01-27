function figure_handle = PTKShow2DSlicesInOneFigure(viewer_panel_handle, orientation, skip_sices, reporting)
    % PTKShowAll2DSlicesInOneFigure. Creates a figure showing every slice from a
    %     PTKViewerPanel object displayed in a grid
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    % Number of plots along x axis
    num_plots_x = 3;
    
    % Maximum number of plots along y axis
    max_plots_y = 4;

    figure_handle = figure;
    axis off;
    hold on;
    gap = 0.01;
    
    number_slices = viewer_panel_handle.BackgroundImage.ImageSize(orientation);
    
    % Ignore slices at beginning and end
    number_slices = number_slices - 2*skip_sices;
    
    max_images_on_page = num_plots_x*max_plots_y;
    slice_spacing = ceil(number_slices/max_images_on_page);
    number_slices_shown = floor(number_slices/slice_spacing);
    
    num_plots_y  = ceil(number_slices_shown/num_plots_x);
    
    panel_slice_number = [1, 1, 1];
    viewer_panel_handle.Orientation = orientation;
    figure_num = 0;
    
    for slice_num = skip_sices : slice_spacing : number_slices + skip_sices
        
        figure_num = figure_num + 1;
        
        % Make viewer display this slice
        panel_slice_number(orientation) = slice_num;
        viewer_panel_handle.SliceNumber = panel_slice_number;
        
        % Capture the frame (including overlay)
        frame = viewer_panel_handle.Capture;
        
        yc = floor((figure_num - 1)/num_plots_x);
        xc = mod(figure_num - 1, num_plots_x);
        y_pos = 1 - yc/num_plots_y;
        y_size =  1/num_plots_y;
        x_pos = xc/num_plots_x;
        x_size =  1/num_plots_x;
        im = frame2im(frame);
        
        % Make figure active
        figure(figure_handle);
        pos = [x_pos + gap, y_pos - y_size + gap, x_size - 2*gap, y_size - 2*gap];
        axes_handle = axes('Position', pos, 'Visible', 'off', 'DataAspectRatio', [1 1 1]);
        image(im);
        set(axes_handle, 'DataAspectRatio', [1 1 1])
        hold on;
        axis off;
        set(axes_handle, 'Units', 'normalized', 'OuterPosition', pos, 'Position', pos);
        set(axes_handle, 'Units', 'normalized', 'OuterPosition', pos, 'Position', pos);
    end
end

