classdef TDLobarHistogram < TDPlugin
    % TDLobarHistogram. Plugin for showing a CT histogram showing the
    %     number of voxels falling into different compartments
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDFrequencyDistribution opens a new window with an annotated CT
    %     histogram as a smoothed curve.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Lobe Histogram'
        ToolTip = 'Shows a histogram of the CT frequency distribution'
        Category = 'Analysis'

        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            results = [];

            roi = dataset.GetResult('TDLungROI');
            
            if ~roi.IsCT
                reporting.ShowMessage('TDLobarHistogram:NotCTImage', 'Cannot perform density analysis as this is not a CT image');
                return;
            end
            
            left_and_right_lungs = dataset.GetResult('TDLeftAndRightLungs');
            
            
            label_font_size = 10;
            legend_font_size = 4;
            compartment_font_size = 6;
            axis_line_width = 1;
            axes_label_font_size = 6;
            widthheightratio = 4/3;
            page_width_cm = 8;
            resolution_dpi = 300;
            compartment_line_width_points = 0.5;
            font_name = 'Arial';

            
            figure_handle = figure;
            set(figure_handle, 'Units','centimeters');
            graph_size = [page_width_cm, (page_width_cm/widthheightratio)];
            
            axes_handle = gca;
            set(figure_handle, 'Name', [roi.Title ' : CT Histogram']);
            set(figure_handle, 'PaperPositionMode', 'auto');
            set(figure_handle, 'position', [0,0, graph_size]);

            hold(axes_handle, 'on');
            axis manual

            
            % Shade the compartments
            max_y = 90;
            rectangle('Parent', axes_handle, 'Position', [-1000, 0, 100, max_y], 'EdgeColor', 'none', 'FaceColor', [0.9 0.9 1])
            rectangle('Parent', axes_handle, 'Position', [ -900, 0, 400, max_y], 'EdgeColor', 'none', 'FaceColor', [0.8 0.8 1])
            rectangle('Parent', axes_handle, 'Position', [ -500, 0, 400, max_y], 'EdgeColor', 'none', 'FaceColor', [0.7 0.7 1])
            rectangle('Parent', axes_handle, 'Position', [ -100, 0, 300, max_y], 'EdgeColor', 'none', 'FaceColor', [0.6 0.6 1])
                        
            
            % Whole lung
            graph_data = [];
            graph_data.Lung = TDLobarHistogram.Histogram(roi, left_and_right_lungs.RawImage > 0, 'k', axes_handle);
            
            % Left and right lungs
            graph_data.Left = TDLobarHistogram.Histogram(roi, left_and_right_lungs.RawImage == 2, 'r', axes_handle);
            graph_data.Right = TDLobarHistogram.Histogram(roi, left_and_right_lungs.RawImage == 1, 'b', axes_handle);

            % Lobes
            lobes = dataset.GetResult('TDLobesFromFissurePlane');
            graph_data.RightUpper = TDLobarHistogram.Histogram(roi, lobes.RawImage == 1, 'b', axes_handle);
            graph_data.RightMid =  TDLobarHistogram.Histogram(roi, lobes.RawImage == 2, 'g', axes_handle);
            graph_data.RightLower = TDLobarHistogram.Histogram(roi, lobes.RawImage == 4, 'c', axes_handle);
            graph_data.LeftUpper = TDLobarHistogram.Histogram(roi, lobes.RawImage == 5, 'm', axes_handle);
            graph_data.LeftLower = TDLobarHistogram.Histogram(roi, lobes.RawImage == 6, 'y', axes_handle);
            legend_strings = {'Whole lung', 'Left lung', 'Right lung', 'Upper right lobe', 'Middle right lobe', 'Lower right lobe', 'Upper left lobe', 'Lower left lobe'};
  
            legend(legend_strings, 'FontName', font_name, 'FontSize', legend_font_size, 'Location', 'SouthEast');

            % Set tick marks
            set(axes_handle, 'XTick', -1000:200:100);
            set(axes_handle, 'YTick', 0:10:max_y);
            set(axes_handle, 'FontSize', axes_label_font_size);
            set(axes_handle, 'LineWidth', axis_line_width);
            
            % Label the compartments
            text('Parent', axes_handle, 'Position', [-900-5, max_y-2], 'String', 'Hyperinflated', 'FontName', font_name, 'HorizontalAlignment', 'Right', 'rotation', 90, 'VerticalAlignment', 'Bottom', 'Color', 'k', 'FontSize', compartment_font_size);
            text('Parent', axes_handle, 'Position', [-500-5, max_y-2], 'String', 'Normally aerated', 'FontName', font_name, 'HorizontalAlignment', 'Right', 'rotation', 90, 'VerticalAlignment', 'Bottom', 'Color', 'k', 'FontSize', compartment_font_size);
            text('Parent', axes_handle, 'Position', [-100-5, max_y-2], 'String', 'Normally aerated', 'FontName', font_name, 'HorizontalAlignment', 'Right', 'rotation', 90, 'VerticalAlignment', 'Bottom', 'Color', 'k', 'FontSize', compartment_font_size);
            text('Parent', axes_handle, 'Position', [ 200-5, max_y-2], 'String', 'Non aerated', 'FontName', font_name, 'HorizontalAlignment', 'Right', 'rotation', 90, 'VerticalAlignment', 'Bottom', 'Color', 'k', 'FontSize', compartment_font_size);
            
            % Draw lines between the compartments
            line('Parent', axes_handle, 'XData', [-1000, -1000], 'YData', [0 max_y], 'Color', 'b', 'LineStyle', '--', 'LineWidth', compartment_line_width_points)
            line('Parent', axes_handle, 'XData', [ -900,  -900], 'YData', [0 max_y], 'Color', 'b', 'LineStyle', '--', 'LineWidth', compartment_line_width_points)
            line('Parent', axes_handle, 'XData', [ -500,  -500], 'YData', [0 max_y], 'Color', 'b', 'LineStyle', '--', 'LineWidth', compartment_line_width_points)
            line('Parent', axes_handle, 'XData', [ -100,  -100], 'YData', [0 max_y], 'Color', 'b', 'LineStyle', '--', 'LineWidth', compartment_line_width_points)
            line('Parent', axes_handle, 'XData', [  200,   200], 'YData', [0 max_y], 'Color', 'b', 'LineStyle', '--', 'LineWidth', compartment_line_width_points)
            
            xlabel(axes_handle, 'CT numbers (Hounsfield Units)', 'FontSize', label_font_size, 'FontName', font_name);
            ylabel(axes_handle, 'CT numbers frequency (%)', 'FontSize', label_font_size, 'FontName', font_name);
            axis(axes_handle, [-1100 200 0 max_y]);

            TDLobarHistogram.SaveToFile(dataset, graph_data, figure_handle, resolution_dpi);

        end
    end
    
    methods (Static, Access = private)
        
        function results = Histogram(lung_roi, region_mask, colour, axes_handle)
            density_values = lung_roi.RawImage(region_mask(:));
            hu_values = double(lung_roi.GreyscaleToHounsfield(density_values));
            number_voxels = length(hu_values);
            
            % Divide the Hounsfield values into 100-unit wide bins
            min_hu_boundary = min(-1000, 100*floor(min(hu_values(:))/100));
            max_hu_boundary = max(200, 100*ceil(max(hu_values(:))/100));
            hu_boundaries = min_hu_boundary - 100 : 100 : max_hu_boundary + 100;
            hu_count = histc(hu_values, hu_boundaries);
            
            % Remove the final count output (which is not a bin value, but 
            % counts voxels exactly on the final boundary - see histc for details)
            hu_count = hu_count(1:end-1);

            % Determine the HU value for each bin
            hu_label = (hu_boundaries(2:end) + hu_boundaries(1:end-1))/2;
            
            % Determine the percentage of voxels in each bin
            hu_percentages = 100*hu_count/number_voxels;
            
            % Compute a smooth spline curve through the data points, enforcing
            % zero end slopes
            hu_spline = -1100 : 5 : 200;
            percentages_spline =  spline(hu_label, [0 hu_percentages' 0]);
            percentages_spline = ppval(percentages_spline, hu_spline)';
            
            % Plot the spline curve
            plot(axes_handle, hu_spline, percentages_spline, colour, 'LineWidth', 1);
            results = [];
            results.Hu = hu_label;
            results.Percentages = hu_percentages;
        end
        
        function SaveToFile(dataset, graph_data, figure_handle, resolution)
            results_directory = TDPTK.GetResultsDirectoryAndCreateIfNecessary;
            image_info = dataset.GetImageInfo;
            uid = image_info.ImageUid;
            file_name = fullfile(results_directory, uid);
            if ~exist(file_name, 'dir')
                mkdir(file_name);
            end
            results_file_name = fullfile(file_name, ['LobeHistogram.txt']);
            file_handle = fopen(results_file_name, 'w');
            
            TDLobarHistogram.SaveLobeToFile(file_handle, graph_data.Lung,       'BOTHLUNG');
            TDLobarHistogram.SaveLobeToFile(file_handle, graph_data.Left,       'LEFTLUNG');
            TDLobarHistogram.SaveLobeToFile(file_handle, graph_data.Right,      'RGHTLUNG');
            TDLobarHistogram.SaveLobeToFile(file_handle, graph_data.RightUpper, 'RGHTUPPR');
            TDLobarHistogram.SaveLobeToFile(file_handle, graph_data.RightMid,   'RGHTMIDL');
            TDLobarHistogram.SaveLobeToFile(file_handle, graph_data.RightLower, 'RGTTLOWR');
            TDLobarHistogram.SaveLobeToFile(file_handle, graph_data.LeftUpper,  'LEFTUPPR');
            TDLobarHistogram.SaveLobeToFile(file_handle, graph_data.LeftLower,  'LEFTLOWR');
            
            fclose(file_handle);
            
            figure_filename_2 = fullfile(file_name, ['LobeHistogram']);
            resolution_str = ['-r' num2str(resolution)];
            
            print(figure_handle, '-depsc2', resolution_str, figure_filename_2);   % Export to .eps
            print(figure_handle, '-dpng', resolution_str, figure_filename_2);     % Export .png
            
        end
        
        function SaveLobeToFile(file_handle, lobe_data, lobe_id)
            number_points = length(lobe_data.Hu);
            for index = 1 : number_points
                hu = lobe_data.Hu(index);
                percentage = lobe_data.Percentages(index);
                output_string = sprintf('%s,%6.6g,%6.6g\r\n', lobe_id, hu, percentage);
                fprintf(file_handle, regexprep(output_string, ' ', ''));
            end
        end        
        
    end
end