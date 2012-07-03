classdef TDDensityVsHeight < TDPlugin
    % TDDensityVsHeight. Plugin for showing a graph relating density to gravitational height
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDDensityVsHeight opens a new window showing the graph.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Density vs Height'
        ToolTip = 'Shows a graph of the density derived from the CT numbers vs height'
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
        function results = RunPlugin(application, reporting)
            results = [];

            lung_roi = application.GetResult('TDLungROI');
            
            if ~lung_roi.IsCT
                reporting.ShowMessage('Cannot perform analysis as this is not a CT image');
                return;
            end
            
            left_and_right_lungs = application.GetResult('TDLeftAndRightLungs');
            surface = application.GetResult('TDLungSurface');
            left_and_right_lungs.ChangeRawImage(left_and_right_lungs.RawImage.*uint8(~surface.RawImage));
            left_lung_results = TDDensityVsHeight.ComputeForLung(lung_roi, find(left_and_right_lungs.RawImage(:) == 2));
            right_lung_results = TDDensityVsHeight.ComputeForLung(lung_roi, find(left_and_right_lungs.RawImage(:) == 1));
            
            max_x = max([left_lung_results.mean_density_values right_lung_results.mean_density_values]);
            max_x = 0.3*ceil(max_x/.3);
            
            if max_x > 0.3
                x_tick_spacing = 0.1;
            else
                x_tick_spacing = 0.05;
            end

            figure_handle = figure;
            axes_handle = gca;
            set(figure_handle, 'Name', [lung_roi.Title ' : Density vs gravitational height']);
            TDDensityVsHeight.Maximize;
            hold(axes_handle, 'on');

            x_ticks = 0 : x_tick_spacing : max_x;

            % Draw lines at 10% gravity intervals
            for g_line = 0:10:100
                h_line = line('Parent', axes_handle, 'XData', [0, max_x], 'YData', [g_line g_line], 'Color', [0.3 0.3 0.3], 'LineStyle', '--');
                set(get(get(h_line,'Annotation'),'LegendInformation'), 'IconDisplayStyle','off'); % Exclude line from legend
            end
            
            % Plot the markers and error bars
            TDDensityVsHeight.PlotForLung(left_lung_results, axes_handle, [0, 0, 1], 'd', 0.2);
            TDDensityVsHeight.PlotForLung(right_lung_results, axes_handle, [1, 0, 0], 's', -0.2);

            % Create the legend
            legend_strings = {'Left', 'Right'};
            legend(legend_strings, 'FontName', 'Helvetica Neue', 'FontSize', 20, 'Location', 'West');
            
            % Set the axes
            xlabel(axes_handle, 'Density (kg/l)', 'FontSize', 20);
            set(gca, 'XTick', x_ticks)
            set(gca, 'XTickLabel', sprintf('%1.4f|', x_ticks))
            ylabel(axes_handle, 'Gravitational height (%)', 'FontSize', 20);
            axis([min(x_ticks) max_x 0 100]);      
        end
        
        function results = ComputeForLung(lung_roi,  voxels_in_lung_indices)
            
            results = [];
            
            % Find the coordinates of each voxel in the lung
            [i_coord, ~, ~] = ind2sub(lung_roi.ImageSize, voxels_in_lung_indices);
            
            density_mg_mL_image = TDConvertCTToDensity(lung_roi);
            
            
            density_mg_mL = density_mg_mL_image.RawImage;
            
            % Compute the gravitatioal height
            height = (lung_roi.ImageSize(1) - i_coord).*lung_roi.VoxelSize(1);
            
            % Width of gravity compartment
            gravity_bin_size = 11;
            
            % Compute the gravity slice positions
            max_gravity = gravity_bin_size*ceil((1+max(height(:)))/gravity_bin_size);
            gravity_bins = 0 : gravity_bin_size : max_gravity;
            
            gravity_plot = [];
            density_plot = [];
            std_plot = [];
            
            for gravity_bin = gravity_bins
                in_bin = (height >= gravity_bin) & (height < (gravity_bin + gravity_bin_size));
                volume_mm3 = sum(in_bin(:)).*prod(lung_roi.VoxelSize);
                
                % Use a cut-off of 5ml
                if (volume_mm3 >= 5000)
                    densities_in_bin_mg_ml = density_mg_mL(in_bin);
                    densities_in_bin_kg_l = densities_in_bin_mg_ml/1000;
                    average_density_for_bin = mean(densities_in_bin_kg_l);
                    std_density_for_bin = std(densities_in_bin_kg_l);
                    
                    % Centrepoint for plot
                    gravity_position = gravity_bin + gravity_bin_size/2;
                    gravity_plot(end+1) = 100*gravity_position/max_gravity;
                    density_plot(end+1) = average_density_for_bin;
                    std_plot(end+1) = std_density_for_bin;
                end
            end
            
            results.gravity_percentage_values = gravity_plot;
            results.mean_density_values = density_plot;
            results.std_values = std_plot;
            
        end
        
        function PlotForLung(results, axes_handle, colour, symbol, errorbar_offset)

            % Plot error bars
            for index = 1 : length(results.mean_density_values)
                density = results.mean_density_values(index);
                gravity = results.gravity_percentage_values(index);
                y_position = gravity + errorbar_offset;
                stdev = results.std_values(index);
                h_line = line('Parent', axes_handle, 'XData', [density - stdev/2, density + stdev/2], 'YData', [y_position, y_position], 'Color', colour, 'LineStyle', '-', 'LineWidth', 2);
                set(get(get(h_line,'Annotation'),'LegendInformation'), 'IconDisplayStyle','off'); % Exclude line from legend
            end

            % Plot markers
            plot(axes_handle, results.mean_density_values, results.gravity_percentage_values, symbol, 'LineWidth', 2, 'MarkerEdgeColor', colour, 'Color', colour, 'MarkerSize', 20, 'MarkerFaceColor', min(1, colour + 0.5));

        end
    end
    
    methods (Static, Access = private)
        
        %maximize Displays a figure full-screen
        function Maximize(fig)
            
            if nargin==0, fig=gcf; end
            
            units=get(fig,'units');
            set(fig,'units','normalized','outerposition',[0 0 1 1]);
            set(fig,'units',units);
        end
    end
end