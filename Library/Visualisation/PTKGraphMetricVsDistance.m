function figure_handle = PTKGraphMetricVsDistance(table, metric, metric_std, context_list, patient_list, distance_label, reporting)
    % PTKGraphMetricVsDistance. Plots a graph showing measurement values for images divided into slices along their axes
    % 
    % PTKGraphMetricVsDistance draws a figure based on results which have been
    % computed by dividing images into bins along one of their axes. See the plugins 
    % PTKSaveAxialAnalysisResults, PTKSaveCoronalAnalysisResults,
    % PTKSaveSaggitalAnalysisResults for examples of how to compute these
    % measurements along the corresponding axes. Once the measurments have been
    % computed and stored in a PTKResultsTable object, call PTKGraphMetricVsDistance
    % to plot a graph based on these results for one or more subjects.
    %    
    % Labels and ticks will be automatically generated from the data.
    %
    % Note the figure is optimised for exporting to a file, not for displaying on-screen. The on-screen figure is not intended for viewing and may have font and graphic sizes in the wrong proportions. To view the figure in its correct proportions, you should export the figure as a graphics file (e.g. png or jpg) and then view the file.
    %
    % Syntax:
    %     figure_handle = PTKGraphMetricVsDistance(table, metric, metric_std, figure_title, context_list, patient_list, reporting)
    %
    % Inputs:
    %     table - a PTKResultsTable containing the data to plot. Only a subset of data will be plotted, determined by the other parameters.
    %     metric - a string containing the id of the metric to plot. This must correspond to the metic id in the table.
    %     metric_std - a string containing the id of the metric to use for the error
    %         bar in the plot. This must correspond to the metic id in the table, or be
    %         empty for no error bar
    %     context_list - Set to [] to plot all contexts, otherwise specify a set of one or more contexts or context sets to plot. Contexts will appear on the x-axis.
    %     patient_list - Set to [] to plot all patients, otherwise specify a set of one of more patient UIDs to appear on the graph.
    %         Each patient will appear with different markers and will appear in the legend.
    %     distance label - The distance label to be used on the x-axis
    %     reporting - Object of class PTKReporting for errors, warnings and progress
    %
    % Output:
    %     figure_handle - the handle of the generated figure. Use this handle to export the figure to an image file
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if isempty(patient_list)
        patient_list = table.IndexMaps{1}.keys;
    end
    

    if isempty(context_list)
        context_list = table.IndexMaps{3}.keys;
    end
    
    if numel(context_list) > 1 && numel(patient_list) > 1
        reporting.Error('PTKGraphMetricVsDistance:MultiplePatientsAndContexts', 'You must specify a single context or a single patient to plot');
    end
    
    flip_left_right = false;
    
    % Decide whether we are going to plot over patients or over contexts
    if numel(patient_list) == 1
        plot_for_contexts = true;
        if iscell(patient_list)
            patient_uid = patient_list{1};
        else
            patient_uid = patient_list;
        end
    else        
        plot_for_contexts = false;
        if iscell(context_list)
            context = context_list{1};
        else
            context = context_list;
        end
    end
    
    
    y_label = table.NameMaps{2}(metric);
    x_label = distance_label;
    
    figure_title = [y_label ' vs ' x_label];
    
    if numel(patient_list) == 1
        figure_title = [figure_title, ' : ', table.NameMaps{1}(patient_list{1})];
    end
    
    
    label_font_size = 10;
    legend_font_size = 9;
    widthheightratio = 4/3;
    page_width_cm = 13;
    font_name = PTKSoftwareInfo.GraphFont;
    line_width = 1.5;
    marker_line_width = 1;
    marker_size = 8;
    
    results_list = {};
    legend_strings = {};
    
    if plot_for_contexts
        for context_list_index = 1 : numel(context_list);
            context = context_list(context_list_index);
            legend_text = table.NameMaps{3}(char(context));
            results_list{context_list_index} = GetResultsFromTable(table, patient_uid, char(context), metric, metric_std, legend_text);
        end
    else
        for patient_list_index = 1 : numel(patient_list)
            patient_uid = patient_list(patient_list_index);
            legend_text = table.NameMaps{1}(patient_uid{1});
            results_list{patient_list_index} = GetResultsFromTable(table, patient_uid{1}, char(context), metric, metric_std, legend_text);
        end
    end
    
    number_of_graphs = numel(results_list);
    errorbar_offsets = linspace(-0.3*number_of_graphs, 0.3*number_of_graphs, number_of_graphs);
    
    colours = {[0, 0, 1], [1, 0, 0], [0, 0.7, 0], [0.7, 0, 0.7], [0, 0.7, 0.7], [0, 0, 0]};
    while numel(colours) < numel(results_list)
        colours = [colours, colours];
    end
    
    symbols = {'d', 's', 'p', 'h', '*', 'o', '^', 'v', '+'};
    while numel(symbols) < numel(results_list)
        symbols = [symbols, symbols];
    end
    
    % Find mimimum and maximum values for x and y
    % We will normalise the x results by the x-maximum    
    [min_x, max_x, min_y, max_y] = GetLimits(results_list);
    
    % Compute normalised distances
    for results_list_index = 1 : numel(results_list);
        results_list{results_list_index}.distance_percentage_values = 100*results_list{results_list_index}.distance_from_origin/max_x;
        if flip_left_right
            results_list{results_list_index}.distance_percentage_values = 100 - results_list{results_list_index}.distance_percentage_values;
        end
        legend_strings{results_list_index} = results_list{results_list_index}.legend;
    end
    
    max_y = 0.1*ceil(max_y/.1);
    
    figure_handle = figure;
    set(figure_handle, 'Units', 'centimeters');
    graph_size = [page_width_cm, (page_width_cm/widthheightratio)];
    
    axes_handle = gca;
    set(figure_handle, 'Name', figure_title);
    set(figure_handle, 'PaperPositionMode', 'auto');
    set(figure_handle, 'position', [0,0, graph_size]);
    hold(axes_handle, 'on');
    
    [y_tick_spacing, min_y, max_y] = PTKGraphUtilities.GetOptimalTickSpacing(min_y, max_y);
    y_ticks = 0 : y_tick_spacing : max_y;
    
    % Draw lines at 10% distance intervals
    for g_line = 0:10:100
        h_line = line('Parent', axes_handle, 'XData', [g_line g_line], 'YData', [0, max_y], 'Color', [0.3 0.3 0.3], 'LineStyle', '--');
        set(get(get(h_line,'Annotation'),'LegendInformation'), 'IconDisplayStyle','off'); % Exclude line from legend
    end
    
    % Plot the markers and error bars
    for results_list_index = 1 : numel(results_list);
        
        colour = colours{results_list_index};
        symbol = symbols{results_list_index};
        errorbar_offset = errorbar_offsets(results_list_index);
        
        PlotForLung(results_list{results_list_index}, axes_handle, colour, symbol, errorbar_offset, marker_size, line_width, marker_line_width);
        
    end
    
    % Create the legend
    legend(legend_strings, 'FontName', font_name, 'FontSize', legend_font_size, 'Location', 'NorthEast');
    
    % Set the axes
    ylabel(axes_handle, y_label, 'FontName', font_name, 'FontSize', label_font_size);
    set(gca, 'YTick', y_ticks)
    
    % Work out number of decimal places for y-axis
    required_num_dp = abs(min(0, floor(log10(y_tick_spacing))));
    
    set(gca, 'YTickLabel', sprintf(['%1.', int2str(required_num_dp), 'f|'], y_ticks))
    xlabel(axes_handle, x_label, 'FontName', font_name, 'FontSize', label_font_size);
    axis([0 100 min(y_ticks) max_y]);
end

function [min_x, max_x, min_y, max_y] = GetLimits(results_list)
    min_x = [];
    max_x = [];
    min_y = [];
    max_y = [];
    
    for results_list_index = 1 : numel(results_list)
        next_result = results_list{results_list_index};
        if isempty(min_x)
            min_x = min(next_result.distance_from_origin);
            max_x = max(next_result.distance_from_origin);
            
            if isempty(next_result.std_values)
                min_y = min((next_result.y_values));
                max_y = max((next_result.y_values));
            else
                min_y = min((next_result.y_values - next_result.std_values/2));
                max_y = max((next_result.y_values + next_result.std_values/2));
            end
            
        else
            min_x = min(min_x, min(next_result.distance_from_origin));
            max_x = max(max_x, max(next_result.distance_from_origin));
            
            if isempty(next_result.std_values)
                min_y = min(min_y, min((next_result.y_values)));
                max_y = max(max_y, max((next_result.y_values)));
            else
                min_y = min(min_y, min((next_result.y_values - next_result.std_values/2)));
                max_y = max(max_y, max((next_result.y_values + next_result.std_values/2)));
            end
            
        end
        
        
    end
end

function results = GetResultsFromTable(table, patient, context, metric, metric_std, legend)
    results = [];
    results.y_values = GetValueListFromTable(table, patient, context, metric);
    if ~isempty(metric_std)
        results.std_values = GetValueListFromTable(table, patient, context, metric_std);
    else
        results.std_values = [];
    end
    results.distance_from_origin = GetValueListFromTable(table, patient, context, 'DistanceFromLungBaseMm');
    results.volume_bin = GetValueListFromTable(table, patient, context, 'VolumeCm3');
    results.legend = legend;
end

function results = GetValueListFromTable(table, patient_uid, context, metric_name)
    patient_index = table.IndexMaps{1}(patient_uid);
    context_index = table.IndexMaps{3}(context);
    metric_index = table.IndexMaps{2}(metric_name);
    results = [table.ResultsTable{patient_index, metric_index, context_index, :}];
end

function PlotForLung(results, axes_handle, colour, symbol, errorbar_offset, marker_size, line_width, marker_line_width)
    
    x_positions = [];
    valid_values = logical.empty;
    
    % Plot error bars
    for index = 1 : length(results.y_values)
        volume_mm3 = 1000*results.volume_bin(index);
        y_values = results.y_values(index);
        distance_percent = results.distance_percentage_values(index);
        x_position = distance_percent + errorbar_offset;
        x_positions(index) = x_position;
        
        valid_values(index) = volume_mm3 >= 5000;
        % Use a cut-off of 5ml
        if valid_values(index)
            if ~isempty(results.std_values)
                stdev = results.std_values(index);
                h_line = line('Parent', axes_handle, 'XData', [x_position, x_position], 'YData', [y_values - stdev/2, y_values + stdev/2], 'Color', colour, 'LineStyle', '-', 'LineWidth', line_width);
                set(get(get(h_line,'Annotation'),'LegendInformation'), 'IconDisplayStyle','off'); % Exclude line from legend
            end
        end
    end
    
    % Plot markers
    
    yv = results.y_values(valid_values);
    xv = x_positions(valid_values);
    plot(axes_handle, xv, yv, symbol, 'LineWidth', marker_line_width, 'MarkerEdgeColor', colour, 'Color', colour, 'MarkerSize', marker_size, 'MarkerFaceColor', min(1, colour + 0.5));
    
end
