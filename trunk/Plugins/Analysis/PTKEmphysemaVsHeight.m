classdef PTKEmphysemaVsHeight < PTKPlugin
    % PTKEmphysemaVsHeight. Plugin for showing a graph relating density to gravitational height
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKEmphysemaVsHeight opens a new window showing the graph.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Emphysema vs Z'
        ToolTip = 'Shows a graph of the emphysema derived from the CT numbers vs height'
        Category = 'Analysis'

        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            lung_roi = dataset.GetResult('PTKLungROI');
            if ~lung_roi.IsCT
                reporting.ShowMessage('PTKEmphysemaVsHeight:NotCTImage', 'Cannot perform analysis as this is not a CT image');
                return;
            end
            
            left_and_right_lungs = dataset.GetResult('PTKLeftAndRightLungs');
            lobes = dataset.GetResult('PTKLobesFromFissurePlane');
            segments = dataset.GetResult('PTKSegmentsByNearestGrowingBronchus');
            surface = dataset.GetResult('PTKLungSurface');
            left_and_right_lungs.ChangeRawImage(left_and_right_lungs.RawImage.*uint8(~surface.RawImage));
            emphysema_image = dataset.GetResult('PTKEmphysemaImage');
            emphysema_image.ResizeToMatch(left_and_right_lungs);
            output_path = dataset.GetOutputPathAndCreateIfNecessary;
            PTKEmphysemaVsHeight.DrawGraphForZAxis(lung_roi, emphysema_image, output_path, left_and_right_lungs, lobes, segments)
            
            results = [];            
        end
        
        function DrawGraphForZAxis(lung_roi, emphysema_image, output_path, left_and_right_lungs, lobes, segments)
            label_font_size = 10;
            legend_font_size = 9;
            widthheightratio = 4/3;
            page_width_cm = 13;
            resolution_dpi = 300;
            font_name = PTKSoftwareInfo.GraphFont;
            line_width = 1.5;
            marker_line_width = 1;
            
            marker_size = 8;
            
            figure_handle = figure;
            set(figure_handle, 'Units', 'centimeters');
            graph_size = [page_width_cm, (page_width_cm/widthheightratio)];
            
            axes_handle = gca;
            set(figure_handle, 'Name', [lung_roi.Title ' : Emphysema vs cranial-caudal distance']);
            set(figure_handle, 'PaperPositionMode', 'auto');
            set(figure_handle, 'position', [0,0, graph_size]);
            hold(axes_handle, 'on');

            
            [global_gravity_bin_boundaries, lung_height_mm] = PTKEmphysemaVsHeight.GetGravityBins(left_and_right_lungs);
            left_lung_results = PTKEmphysemaVsHeight.ComputeForLung(lung_roi, find(left_and_right_lungs.RawImage(:) == 2), global_gravity_bin_boundaries, lung_height_mm, emphysema_image);
            right_lung_results = PTKEmphysemaVsHeight.ComputeForLung(lung_roi, find(left_and_right_lungs.RawImage(:) == 1), global_gravity_bin_boundaries, lung_height_mm, emphysema_image);

            ru = PTKEmphysemaVsHeight.ComputeForLung(lung_roi, find(lobes.RawImage(:) == 1), global_gravity_bin_boundaries, lung_height_mm, emphysema_image);
            rl = PTKEmphysemaVsHeight.ComputeForLung(lung_roi, find(lobes.RawImage(:) == 4), global_gravity_bin_boundaries, lung_height_mm, emphysema_image);
            rm = PTKEmphysemaVsHeight.ComputeForLung(lung_roi, find(lobes.RawImage(:) == 2), global_gravity_bin_boundaries, lung_height_mm, emphysema_image);
            lu = PTKEmphysemaVsHeight.ComputeForLung(lung_roi, find(lobes.RawImage(:) == 5), global_gravity_bin_boundaries, lung_height_mm, emphysema_image);
            ll = PTKEmphysemaVsHeight.ComputeForLung(lung_roi, find(lobes.RawImage(:) == 6), global_gravity_bin_boundaries, lung_height_mm, emphysema_image);
            
%             segment_results = [];
%             segment_labels = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20};
% 
%             
%             for segment_index = segment_labels
%                 label = segment_index{1};
%                 segment_results{label} = PTKEmphysemaVsHeight.ComputeForLung(lung_roi, find(segments.RawImage(:) == label), global_gravity_bin_boundaries, lung_height_mm, emphysema_image);
%             end
            
            max_y = max([(left_lung_results.emphysema_percentages) (right_lung_results.emphysema_percentages)]);
            max_y = 5*ceil(max_y/5);
            
            if max_y > 10
                y_tick_spacing = 10;
            else
                y_tick_spacing = 1;
            end

            y_ticks = 0 : y_tick_spacing : max_y;

            % Draw lines at 10% gravity intervals
            for g_line = 0:10:100
                h_line = line('Parent', axes_handle, 'YData', [0, max_y], 'XData', [g_line g_line], 'Color', [0.3 0.3 0.3], 'LineStyle', '--');
                set(get(get(h_line,'Annotation'),'LegendInformation'), 'IconDisplayStyle','off'); % Exclude line from legend
            end
            
            % Plot the markers and error bars
%             PTKEmphysemaVsHeight.PlotForLung(left_lung_results, axes_handle, [0, 0, 1], 'd', 0.2, marker_size, line_width, marker_line_width);
%             PTKEmphysemaVsHeight.PlotForLung(right_lung_results, axes_handle, [1, 0, 0], 's', -0.2, marker_size, line_width, marker_line_width);

            PTKEmphysemaVsHeight.PlotForLung(ru, axes_handle, [0, 0, 1], 's-', -0.2, marker_size, line_width, marker_line_width);
            PTKEmphysemaVsHeight.PlotForLung(rl, axes_handle, [0, 1, 0], 's-', -0.2, marker_size, line_width, marker_line_width);
            PTKEmphysemaVsHeight.PlotForLung(rm, axes_handle, [0, 1, 1], 's-', -0.2, marker_size, line_width, marker_line_width);
            PTKEmphysemaVsHeight.PlotForLung(lu, axes_handle, [1, 0, 1], 'd-', -0.2, marker_size, line_width, marker_line_width);
            PTKEmphysemaVsHeight.PlotForLung(ll, axes_handle, [1, 1, 0], 'd-', -0.2, marker_size, line_width, marker_line_width);

%             for segment_index = segment_labels
%                 label = segment_index{1};
%                 PTKEmphysemaVsHeight.PlotForLung(segment_results{label}, axes_handle, [0, 0, 1], 'x--', -0.2, marker_size, line_width, marker_line_width);
%             end
            
            
            % Create the legend
%             legend_strings = {'Left', 'Right'};
            legend_strings = {'RU', 'RL', 'RM', 'LU', 'LL'};
            segment_legend_strings = {'R_AP', 'R_P', 'R_AN', 'R_L', 'R_M', 'R_S', 'R_MB', 'R_AB', 'R_LB', 'R_PB', ...
                'L_AP', 'L_APP2', 'L_AN', 'L_SL', 'L_IL', 'L_S', 'L_AMB', 'L_LB' 'L_PB'};
            legend_strings = [legend_strings, segment_legend_strings];
            
            legend(legend_strings, 'FontName', font_name, 'FontSize', legend_font_size, 'Location', 'East');
            
            % Set the axes
            ylabel(axes_handle, 'Emphysema (%)', 'FontName', font_name, 'FontSize', label_font_size);
            set(gca, 'YTick', y_ticks)
            set(gca, 'YTickLabel', sprintf('%1.1f|', y_ticks))
            xlabel(axes_handle, 'Cranial-caudal distance from base (%)', 'FontName', font_name, 'FontSize', label_font_size);
            axis([0 100 min(y_ticks) max_y]);
            
            PTKEmphysemaVsHeight.SaveToFile(output_path, left_lung_results, right_lung_results, figure_handle, resolution_dpi);
        end
        
        function [global_gravity_bin_boundaries, lung_height_mm] = GetGravityBins(whole_lung_mask)
            bounds = whole_lung_mask.GetBounds;
            min_k = bounds(5);
            max_k = bounds(6);
            
            k_offset_mm = (min_k + whole_lung_mask.Origin(3) - 2)*whole_lung_mask.VoxelSize(3);
            lung_height_mm = (1 + max_k - min_k)*whole_lung_mask.VoxelSize(3);
            slice_height_mm = 16;
            
            global_gravity_bin_boundaries = 0 : slice_height_mm : lung_height_mm;
            global_gravity_bin_boundaries = global_gravity_bin_boundaries + k_offset_mm;
        end
        
        function results = ComputeForLung(lung_roi, voxels_in_lung_indices, global_gravity_bin_boundaries, lung_height_mm, emphysema_image)
            
            results = [];
            
            % Convert the local indices passed in to global coordinates in mm
            % For a supine patient, the i cordinate is the gravitational height
            % from the bottom of the original image
            global_indices = lung_roi.LocalToGlobalIndices(voxels_in_lung_indices);
            [~, ~, k_coord] = lung_roi.GlobalIndicesToCoordinatesMm(global_indices);
            height = k_coord;
            
            gravity_bin_size = global_gravity_bin_boundaries(2) - global_gravity_bin_boundaries(1);
            gravity_bins = global_gravity_bin_boundaries;
                                    
            gravity_plot = [];
            emphysema_plot = [];
            volume_bin = [];
            
            emphysema_image.ChangeRawImage(uint8(emphysema_image.RawImage == 3));
            
            for gravity_bin = gravity_bins
                in_bin = (height >= gravity_bin) & (height < (gravity_bin + gravity_bin_size));
                volume_mm3 = sum(in_bin(:))*prod(lung_roi.VoxelSize);
                
                emphysema_in_bin = emphysema_image.RawImage(voxels_in_lung_indices(in_bin));
                emphysema_percentage_inbin = 100*sum(emphysema_in_bin)/numel(emphysema_in_bin);
                
                % Centrepoint for plot
                gravity_position = gravity_bin + gravity_bin_size/2;
                gravity_plot(end+1) = 100 - 100*(gravity_position - global_gravity_bin_boundaries(1))/lung_height_mm;
                emphysema_plot(end+1) = emphysema_percentage_inbin;
                volume_bin(end+1) = volume_mm3;
            end
            
            results.gravity_percentage_values = gravity_plot;
            results.emphysema_percentages = emphysema_plot;
            results.volume_bin = volume_bin;
        end
        
        function PlotForLung(results, axes_handle, colour, symbol, errorbar_offset, marker_size, line_width, marker_line_width)

            % Plot markers
            plot(axes_handle, results.gravity_percentage_values, results.emphysema_percentages, symbol, 'LineWidth', marker_line_width, 'MarkerEdgeColor', colour, 'Color', colour, 'MarkerSize', marker_size, 'MarkerFaceColor', min(1, colour + 0.5));

        end
    end
    
    methods (Static, Access = private)
        function SaveToFile(output_path, left_lung_results, right_lung_results, figure_handle, resolution)
            results_file_name = fullfile(output_path, ['EmphysemaVsCranialCaudalDistance.txt']);
            file_handle = fopen(results_file_name, 'w');
            
            number_points = length(left_lung_results.emphysema_percentages);
            for index = 1 : number_points
                left_emphysema = left_lung_results.emphysema_percentages(index);
                right_emphysema = right_lung_results.emphysema_percentages(index);
                gravity_percentage = left_lung_results.gravity_percentage_values(index);
                left_volume_mm = left_lung_results.volume_bin(index);
                right_volume_mm = right_lung_results.volume_bin(index);
                output_string = sprintf('%6.6g,%6.6g,%6.6g,%6.6g,%6.6g\r\n', gravity_percentage, left_emphysema, right_emphysema, left_volume_mm, right_volume_mm);
                fprintf(file_handle, regexprep(output_string, ' ', ''));
            end
            
            fclose(file_handle);
            
            figure_filename_2 = fullfile(output_path, ['EmphysemaVsCranialCaudalDistance']);
            resolution_str = ['-r' num2str(resolution)];
            
            print(figure_handle, '-depsc2', resolution_str, figure_filename_2);   % Export to .eps
            print(figure_handle, '-dpng', resolution_str, figure_filename_2);     % Export .png            
        end
    end
end