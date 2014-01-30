function figure_handle = PTKDrawMetricVsDistance(table, patient_name, metric, metric_std, figure_title, y_label, context_list)
    % PTKDrawMetricVsDistance.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    x_label = table.NameMaps{2}(metric);

    number_of_graphs = numel(context_list);
    errorbar_offsets = linspace(-0.2*number_of_graphs, 0.2*number_of_graphs, number_of_graphs);
    
    colours = {[0, 0, 1], [1, 0, 0], [0, 0.7, 0], [0.7, 0, 0.7], [0, 0.7, 0.7], [0, 0, 0]};
    while numel(colours) < numel(context_list)
        colours = [colours, colours];
    end
    
    symbols = {'d', 's', 'p', 'h', '*', 'o', '^', 'v', '+'};
    while numel(symbols) < numel(context_list)
        symbols = [symbols, symbols];
    end
    
    label_font_size = 10;
    legend_font_size = 9;
    widthheightratio = 4/3;
    page_width_cm = 13;
    font_name = PTKSoftwareInfo.GraphFont;
    line_width = 1.5;
    marker_line_width = 1;
    marker_size = 8;
    
    max_y = 0;
    max_x = 0;
    context_results = {};
    legend_strings = {};
    for context_list_index = 1 : numel(context_list);
        context = context_list(context_list_index);
        next_context_result = GetResultsFromTable(table, char(context), metric, metric_std);
        max_y = max(max_y, max(next_context_result.distance_from_origin));
        if isempty(next_context_result.std_values)
            max_x = max(max_x, max((next_context_result.x_values)));
        else
            max_x = max(max_x, max((next_context_result.x_values + next_context_result.std_values/2)));
        end
        context_results{context_list_index} = next_context_result;
        legend_strings{context_list_index} = table.NameMaps{3}(char(context));
    end
    
    for context_list_index = 1 : numel(context_list);
        context_results{context_list_index}.distance_percentage_values = 100 - 100*context_results{context_list_index}.distance_from_origin/max_y;
    end
    
    max_x = 0.3*ceil(max_x/.3);
    
    if max_x > 1
        power_of_10 = log10(max_x);
        frac = power_of_10 - floor(power_of_10);
        power_of_10 = floor(power_of_10) + (frac > 0.7) - 1;
        x_tick_spacing = max_x / 5;
        x_tick_spacing = (10^power_of_10)*round(x_tick_spacing/(10^power_of_10));
    elseif max_x > 0.3
        x_tick_spacing = 0.1;
    else
        x_tick_spacing = 0.05;
    end
    
    figure_handle = figure;
    set(figure_handle, 'Units', 'centimeters');
    graph_size = [page_width_cm, (page_width_cm/widthheightratio)];
    
    axes_handle = gca;
    set(figure_handle, 'Name', [patient_name ' : ' figure_title]);
    set(figure_handle, 'PaperPositionMode', 'auto');
    set(figure_handle, 'position', [0,0, graph_size]);
    hold(axes_handle, 'on');
    
    x_ticks = 0 : x_tick_spacing : max_x;
    
    % Draw lines at 10% distance intervals
    for g_line = 0:10:100
        h_line = line('Parent', axes_handle, 'XData', [0, max_x], 'YData', [g_line g_line], 'Color', [0.3 0.3 0.3], 'LineStyle', '--');
        set(get(get(h_line,'Annotation'),'LegendInformation'), 'IconDisplayStyle','off'); % Exclude line from legend
    end
    
    % Plot the markers and error bars
    for context_list_index = 1 : numel(context_list);
        
        colour = colours{context_list_index};
        symbol = symbols{context_list_index};
        errorbar_offset = errorbar_offsets(context_list_index);
        
        PlotForLung(context_results{context_list_index}, axes_handle, colour, symbol, errorbar_offset, marker_size, line_width, marker_line_width);
        
    end
    
    % Create the legend
    legend(legend_strings, 'FontName', font_name, 'FontSize', legend_font_size, 'Location', 'East');
    
    % Set the axes
    xlabel(axes_handle, x_label, 'FontName', font_name, 'FontSize', label_font_size);
    set(gca, 'XTick', x_ticks)
    set(gca, 'XTickLabel', sprintf('%1.2f|', x_ticks))
    ylabel(axes_handle, y_label, 'FontName', font_name, 'FontSize', label_font_size);
    axis([min(x_ticks) max_x 0 100]);
end

function results = GetResultsFromTable(table, context, metric, metric_std)
    results = [];
    results.x_values = GetValueListFromTable(table, context, metric);
    if ~isempty(metric_std)
        results.std_values = GetValueListFromTable(table, context, metric_std);
    else
        results.std_values = [];
    end
    results.distance_from_origin = GetValueListFromTable(table, context, 'DistanceFromLungBaseMm');
    results.volume_bin = GetValueListFromTable(table, context, 'VolumeCm3');
end

function results = GetValueListFromTable(table, context, metric_name)
    patient_index = 1;
    context_index = table.IndexMaps{3}(context);
    metric_index = table.IndexMaps{2}(metric_name);
    results = [table.ResultsTable{patient_index, metric_index, context_index, :}];
end

function PlotForLung(results, axes_handle, colour, symbol, errorbar_offset, marker_size, line_width, marker_line_width)
    
    y_positions = [];
    valid_values = logical.empty;
    
    % Plot error bars
    for index = 1 : length(results.x_values)
        volume_mm3 = 1000*results.volume_bin(index);
        x_values = results.x_values(index);
        distance_percent = results.distance_percentage_values(index);
        y_position = distance_percent + errorbar_offset;
        y_positions(index) = y_position;
        
        valid_values(index) = volume_mm3 >= 5000;
        % Use a cut-off of 5ml
        if valid_values(index)
            if ~isempty(results.std_values)
                stdev = results.std_values(index);
                h_line = line('Parent', axes_handle, 'XData', [x_values - stdev/2, x_values + stdev/2], 'YData', [y_position, y_position], 'Color', colour, 'LineStyle', '-', 'LineWidth', line_width);
                set(get(get(h_line,'Annotation'),'LegendInformation'), 'IconDisplayStyle','off'); % Exclude line from legend
            end
        end
    end
    
    % Plot markers
    
    xv = results.x_values(valid_values);
    yv = y_positions(valid_values);
    plot(axes_handle, xv, yv, symbol, 'LineWidth', marker_line_width, 'MarkerEdgeColor', colour, 'Color', colour, 'MarkerSize', marker_size, 'MarkerFaceColor', min(1, colour + 0.5));
    
end
