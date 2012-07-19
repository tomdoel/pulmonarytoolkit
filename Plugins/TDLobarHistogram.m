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
            
            
            figure_handle = figure;
            axes_handle = gca;
            set(figure_handle, 'Name', [roi.Title ' : CT Histogram']);
            TDLobarFrequencyDistribution.Maximize;
            
            hold(axes_handle, 'on');
            
            % Shade the compartments
            max_y = 70;
            rectangle('Parent', axes_handle, 'Position', [-1000, 0, 100, max_y], 'EdgeColor', 'none', 'FaceColor', [0.9 0.9 1])
            rectangle('Parent', axes_handle, 'Position', [ -900, 0, 400, max_y], 'EdgeColor', 'none', 'FaceColor', [0.8 0.8 1])
            rectangle('Parent', axes_handle, 'Position', [ -500, 0, 400, max_y], 'EdgeColor', 'none', 'FaceColor', [0.7 0.7 1])
            rectangle('Parent', axes_handle, 'Position', [ -100, 0, 300, max_y], 'EdgeColor', 'none', 'FaceColor', [0.6 0.6 1])
                        
            
            % Whole lung
            graph_data = [];
            graph_data.Lung = TDLobarFrequencyDistribution.Histogram(roi, left_and_right_lungs.RawImage > 0, 'k', axes_handle);
            
            % Left and right lungs
            graph_data.Left = TDLobarFrequencyDistribution.Histogram(roi, left_and_right_lungs.RawImage == 2, 'r', axes_handle);
            graph_data.Right = TDLobarFrequencyDistribution.Histogram(roi, left_and_right_lungs.RawImage == 1, 'b', axes_handle);

            % Lobes
            lobes = dataset.GetResult('TDLobesFromFissurePlane');
            graph_data.RightUpper = TDLobarFrequencyDistribution.Histogram(roi, lobes.RawImage == 1, 'b', axes_handle);
            graph_data.RightMid =  TDLobarFrequencyDistribution.Histogram(roi, lobes.RawImage == 2, 'g', axes_handle);
            graph_data.RightLower = TDLobarFrequencyDistribution.Histogram(roi, lobes.RawImage == 4, 'c', axes_handle);
            graph_data.LeftUpper = TDLobarFrequencyDistribution.Histogram(roi, lobes.RawImage == 5, 'm', axes_handle);
            graph_data.LeftLower = TDLobarFrequencyDistribution.Histogram(roi, lobes.RawImage == 6, 'y', axes_handle);
            legend_strings = {'Whole lung', 'Left lung', 'Right lung', 'Upper right lobe', 'Middle right lobe', 'Lower right lobe', 'Upper left lobe', 'Lower left lobe'};
  
            legend(legend_strings, 'FontName', 'Helvetica Neue', 'FontSize', 20, 'Location', 'East');

            % Set tick marks
            set(axes_handle, 'XTick', -1000:100:100);
            set(axes_handle, 'YTick', 0:10:50);
            
            % Label the compartments
            text('Parent', axes_handle, 'Position', [-900-5, max_y-2], 'String', 'Hyperinflated', 'FontName', 'Helvetica Neue', 'HorizontalAlignment', 'Right', 'rotation', 90, 'VerticalAlignment', 'Bottom', 'Color', 'k', 'FontSize', 20);
            text('Parent', axes_handle, 'Position', [-500-5, max_y-2], 'String', 'Normally aerated', 'FontName', 'Helvetica Neue', 'HorizontalAlignment', 'Right', 'rotation', 90, 'VerticalAlignment', 'Bottom', 'Color', 'k', 'FontSize', 20);
            text('Parent', axes_handle, 'Position', [-100-5, max_y-2], 'String', 'Normally aerated', 'FontName', 'Helvetica Neue', 'HorizontalAlignment', 'Right', 'rotation', 90, 'VerticalAlignment', 'Bottom', 'Color', 'k', 'FontSize', 20);
            text('Parent', axes_handle, 'Position', [ 200-5, max_y-2], 'String', 'Non aerated', 'FontName', 'Helvetica Neue', 'HorizontalAlignment', 'Right', 'rotation', 90, 'VerticalAlignment', 'Bottom', 'Color', 'k', 'FontSize', 20);
            
            % Draw lines between the compartments
            line('Parent', axes_handle, 'XData', [-1000, -1000], 'YData', [0 max_y], 'Color', 'b', 'LineStyle', '--')
            line('Parent', axes_handle, 'XData', [ -900,  -900], 'YData', [0 max_y], 'Color', 'b', 'LineStyle', '--')
            line('Parent', axes_handle, 'XData', [ -500,  -500], 'YData', [0 max_y], 'Color', 'b', 'LineStyle', '--')
            line('Parent', axes_handle, 'XData', [ -100,  -100], 'YData', [0 max_y], 'Color', 'b', 'LineStyle', '--')
            line('Parent', axes_handle, 'XData', [  200,   200], 'YData', [0 max_y], 'Color', 'b', 'LineStyle', '--')
            
            xlabel(axes_handle, 'CT numbers (Hounsfield Units)', 'FontSize', 20);
            ylabel(axes_handle, 'CT numbers frequency (%)', 'FontSize', 20);
            axis(axes_handle, [-1100 200 0 max_y]);

            TDLobarFrequencyDistribution.SaveToFile(dataset, graph_data, figure_handle);

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
            plot(axes_handle, hu_spline, percentages_spline, colour, 'LineWidth', 2);
            results = [];
            results.Hu = hu_label;
            results.Percentages = hu_percentages;
        end
        
        %maximize Displays a figure full-screen
        function Maximize(fig)
            
            if nargin==0, fig=gcf; end
            
            units=get(fig,'units');
            set(fig,'units','normalized','outerposition',[0 0 1 1]);
            set(fig,'units',units);
        end
        
        function SaveToFile(dataset, graph_data, figure_handle)
            results_directory = TDPTK.GetResultsDirectoryAndCreateIfNecessary;
            image_info = dataset.GetImageInfo;
            uid = image_info.ImageUid;
            file_name = fullfile(results_directory, uid);
            if ~exist(file_name, 'dir')
                mkdir(file_name);
            end
            results_file_name = fullfile(file_name, ['LobeHistogram.txt']);
            file_handle = fopen(results_file_name, 'w');
            
            TDLobarFrequencyDistribution.SaveLobeToFile(file_handle, graph_data.Lung,       'BOTHLUNG');
            TDLobarFrequencyDistribution.SaveLobeToFile(file_handle, graph_data.Left,       'LEFTLUNG');
            TDLobarFrequencyDistribution.SaveLobeToFile(file_handle, graph_data.Right,      'RGHTLUNG');
            TDLobarFrequencyDistribution.SaveLobeToFile(file_handle, graph_data.RightUpper, 'RGHTUPPR');
            TDLobarFrequencyDistribution.SaveLobeToFile(file_handle, graph_data.RightMid,   'RGHTMIDL');
            TDLobarFrequencyDistribution.SaveLobeToFile(file_handle, graph_data.RightLower, 'RGTTLOWR');
            TDLobarFrequencyDistribution.SaveLobeToFile(file_handle, graph_data.LeftUpper,  'LEFTUPPR');
            TDLobarFrequencyDistribution.SaveLobeToFile(file_handle, graph_data.LeftLower,  'LEFTLOWR');
            
            fclose(file_handle);
            figure_filename = fullfile(file_name, ['LobeHistogram.tif']);
            saveas(figure_handle, figure_filename);
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