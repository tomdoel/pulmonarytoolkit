function figure_handle = PTKDrawMetricVsMetric(table, metric_x, metric_y, context_list)
    % PTKDrawMetricVsMetric.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    x_label = table.NameMaps{2}(metric_x);
    y_label = table.NameMaps{2}(metric_y);

    number_of_subjects = table.IndexMaps{1}.Count;
    number_of_points_per_subject = numel(context_list);
    
    colours = {[0, 0, 1], [1, 0, 0], [0, 0.7, 0], [0.7, 0, 0.7], [0, 0.7, 0.7], [0, 0, 0]};
    while numel(colours) < number_of_subjects
        colours = [colours, colours];
    end
    
    symbols = {'d', 's', 'p', 'h', '*', 'o', '^', 'v', '+'};
    while numel(symbols) < number_of_subjects
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
    
    result_list = [];
    
    patient_uids = table.NameMaps{1}.keys;
    
    max_x = 0;
    max_y = 0;
    
    for patient_iterator = 1 : number_of_subjects
        patient_uid = patient_uids{patient_iterator};
        patient_index = table.IndexMaps{1}(patient_uid);
        result_list{patient_iterator} = GetResultsFromTable(table, patient_uid, metric_x, metric_y, context_list);
        
        % Find the maxima
        max_x = max(max_x, max(result_list{patient_iterator}.x_values));
        max_y = max(max_y, max(result_list{patient_iterator}.y_values));
        
        legend_strings{patient_iterator} = table.NameMaps{1}(patient_uid);
    end
    
    % Work out tick spacing for x and y axes
    x_tick_spacing = PTKGraphUtilities.GetOptimalTickSpacing(0, max_x);
    y_tick_spacing = PTKGraphUtilities.GetOptimalTickSpacing(0, max_y);

    figure_handle = figure;
    set(figure_handle, 'Units', 'centimeters');
    graph_size = [page_width_cm, (page_width_cm/widthheightratio)];
    
    axes_handle = gca;
    set(figure_handle, 'Name', [x_label ' : ' y_label]);
    set(figure_handle, 'PaperPositionMode', 'auto');
    set(figure_handle, 'position', [0,0, graph_size]);
    hold(axes_handle, 'on');
    
    x_ticks = 0 : x_tick_spacing : max_x;
    y_ticks = 0 : y_tick_spacing : max_y;
    
    % Plot the markers and error bars
    for patient_list_index = 1 : number_of_subjects
        
        colour = colours{patient_list_index};
        symbol = symbols{patient_list_index};
        
        PlotForLung(result_list{patient_list_index}, axes_handle, colour, symbol, marker_size, marker_line_width);
        
    end
    
    % Create the legend
    legend(legend_strings, 'FontName', font_name, 'FontSize', legend_font_size, 'Location', 'SouthEast');
    
    % Set the axes
    xlabel(axes_handle, x_label, 'FontName', font_name, 'FontSize', label_font_size);
    set(gca, 'XTick', x_ticks)
    set(gca, 'XTickLabel', sprintf('%1.2f|', x_ticks))
    set(gca, 'YTick', y_ticks)
    ylabel(axes_handle, y_label, 'FontName', font_name, 'FontSize', label_font_size);
    axis([min(x_ticks) max_x 0 max_y]);
end

function results = GetResultsFromTable(table, patient_name, x_metric, y_metric, context_list)
    results = [];
    results.x_values = cell2mat(PTKContainerUtilities.CellEmptyToNan(GetValueListFromTable(table, patient_name, x_metric, context_list)));
    results.y_values = cell2mat(PTKContainerUtilities.CellEmptyToNan(GetValueListFromTable(table, patient_name, y_metric, context_list)));
    invalid = isnan(results.x_values) | isnan(results.y_values);
    results.x_values = results.x_values(~invalid);
    results.y_values = results.y_values(~invalid);
end

function results = GetValueListFromTable(table, patient_name, metric_name, context_list)
    patient_index = table.IndexMaps{1}(patient_name);
    metric_index = table.IndexMaps{2}(metric_name);
    
    results = [];
    
    for context = context_list
        context_index = table.IndexMaps{3}(char(context));
        results{end + 1} = table.ResultsTable{patient_index, metric_index, context_index, :};
    end
end

function PlotForLung(results, axes_handle, colour, symbol, marker_size, marker_line_width)
    
    % Plot markers    
    xv = results.x_values;
    yv = results.y_values;
    plot(axes_handle, xv, yv, symbol, 'LineWidth', marker_line_width, 'MarkerEdgeColor', colour, 'Color', colour, 'MarkerSize', marker_size, 'MarkerFaceColor', min(1, colour + 0.5));
    
end
