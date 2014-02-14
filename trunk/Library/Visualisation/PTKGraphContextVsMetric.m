function figure_handle = PTKGraphContextVsMetric(table, metric, context_list, patient_uids)
    % PTKGraphContextVsMetric. Plots a graph showing measurement values against lung regions for one or more subjects
    % 
    % PTKGraphContextVsMetric creates a figure and plots a graph showing measurements for particular lung regions, for one or more patients.
    %
    % The data to plot must be held in a PTKResultsTable. You specify which contexts (regions), which metric (measurement) and which patients to plot.
    % The contexts (regions) will be shown along the x-axis, and the values of the metric will be shown on the y-axis.
    %
    % Labels and ticks will be automatically generated from the data.
    %
    % Note the figure is optimised for exporting to a file, not for displaying on-screen. The on-screen figure is not intended for viewing and may have font and graphic sizes in the wrong proportions. To view the figure in its correct proportions, you should export the figure as a graphics file (e.g. png or jpg) and then view the file.
    %
    % Syntax:
    %     figure_handle = PTKGraphContextVsMetric(table, metric, context_list, patient_uids)
    %
    % Inputs:
    %     table - a PTKResultsTable containing the data to plot. Only a subset of data will be plotted, determined by the other parameters.
    %     metric - a string containing the id of the metric to plot. This must correspond to the metic id in the table.
    %     context_list - Set to [] to plot all contexts, otherwise specify a set of one or more contexts or context sets to plot. Contexts will appear on the x-axis.
    %     patient_uids - Set to [] to plot all patients, otherwise specify a set of one of more patient UIDs to appear on the graph.
    %         Each patient will appear with different markers and will appear in the legend.
    %
    % Output:
    %     figure_handle - the handle of the generated figure. Use this handle to export the figure to an image file
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if nargin < 4
        patient_uids = table.NameMaps{1}.keys;
    end
    
    y_label = table.NameMaps{2}(metric);
    
    if nargin < 3 || isempty(context_list)
        context_list = table.IndexMaps{3}.keys;
    end
    
    context_list = SortContexts(context_list);
    
    metrix_index = table.IndexMaps{2}(metric);
    
    
    
    
    number_of_subjects = numel(patient_uids);
    
    colours = {[0, 0.7, 0.7], [0, 0, 1], [1, 0, 0], [0.7, 0, 0.7], [0, 0.7, 0], [0, 0, 0]};
    while numel(colours) < number_of_subjects
        colours = [colours, colours];
    end
    
    symbols = {'^', 'd', 'p', 'h', 's', 'o', '^', '*', 'v', '+'};
    while numel(symbols) < number_of_subjects
        symbols = [symbols, symbols];
    end
    
    label_font_size = 10;
    x_tick_label_size = 10;
    y_tick_label_size = 8;
    x_lung_label_size = 8;
    if numel(context_list) > 10
        x_tick_label_size = 5;
    end
    
    right_lung_colour = [0.7, 0, 0];
    left_lung_colour = [0, 0, 0.7];
    
    legend_font_size = 5;
    widthheightratio = 4/3;
    page_width_cm = 13;
    font_name = PTKSoftwareInfo.GraphFont;
    marker_line_width = 1;
    context_line_width = 1;
    marker_size = 8;
    legend_marker_size = 6;
    
    legend_strings = {};
    
    max_y = 0;
    min_y = [];
    
    context_labels = {};
    
    for context_list_index = 1 : numel(context_list)
        if ~isempty(context_list{context_list_index})
            context_text_label = table.NameMaps{3}(char(context_list{context_list_index}));
            if length(context_text_label) > 2
                if strcmp(context_text_label(1:2), 'R_') || strcmp(context_text_label(1:2), 'L_')
                    context_text_label = context_text_label(3:end);
                end
            end
            context_labels{end + 1} = context_text_label;
        end
    end
    
    figure_handle = figure;
    set(figure_handle, 'Units', 'centimeters');
    graph_size = [page_width_cm, (page_width_cm/widthheightratio)];
    
    axes_handle = gca;
    set(figure_handle, 'Name', y_label);
    set(figure_handle, 'PaperPositionMode', 'auto');
    set(figure_handle, 'position', [0,0, graph_size]);
    hold(axes_handle, 'on');
    
    x_ticks = [];
    max_x = 0;
    
    plots = [];
    right_lung_segments_label_position = [];
    left_lung_segments_label_position = [];
    
    x_ticks_color_map = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    x_ticks_label_map = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    
    
    for patient_iterator = 1 : number_of_subjects
        patient_uid = patient_uids{patient_iterator};
        patient_index = table.IndexMaps{1}(patient_uid);
        
        x_coords = [];
        y_coords = [];
        
        x_coord = 1;
        
        for context_list_index = 1 : numel(context_list)
            this_context = char(context_list{context_list_index});
            if ~isempty(this_context)
                context_colour = [0.1, 0.1, 0.1];
                if length(this_context) > 1
                    if strcmp(this_context(1:2), 'R_')
                        context_colour = right_lung_colour;
                    elseif strcmp(this_context(1:2), 'L_')
                        context_colour = left_lung_colour;
                    end
                end
                
                
                if strcmp(this_context, 'R_M')
                    right_lung_segments_label_position = x_coord + 0.5;
                elseif strcmp(this_context, 'L_IL')
                    left_lung_segments_label_position = x_coord;
                end
                context_table_index = table.IndexMaps{3}(char(this_context));
                result = table.ResultsTable{patient_index, metrix_index, context_table_index, :};
                if ~isempty(result)
                    x_coords(end + 1) = x_coord;
                    x_ticks = union(x_ticks, x_coord);
                    y_coords(end + 1) = result;
                    x_ticks_color_map(x_coord) = {context_colour};
                    
                    context_text_label = table.NameMaps{3}(this_context);
                    if length(context_text_label) > 2
                        if strcmp(context_text_label(1:2), 'R_') || strcmp(context_text_label(1:2), 'L_')
                            context_text_label = context_text_label(3:end);
                        end
                    end
                    context_labels{end + 1} = context_text_label;
                    
                    x_ticks_label_map(x_coord) = {context_text_label};
                end
            end
            x_coord = x_coord + 1;
        end
        
        colour = colours{patient_iterator};
        symbol = symbols{patient_iterator};
        marker_face_colour = min(1, colour + 0.5);
        
        plots_info = [];
        plots_info.X = x_coords;
        plots_info.Y = y_coords;
        plots_info.Symbol = symbol;
        plots_info.Colour = colour;
        plots_info.MarkerFaceColour = marker_face_colour;
        
        plots{patient_iterator} = plots_info;
        
        
        % Find the maxima and maxima
        if isempty(min_y)
            min_y = min(y_coords(:));
        else
            min_y = min(min_y, min(y_coords(:)));
        end
        
        max_y = max(max_y, max(y_coords(:)));
        
        max_x = max(max_x, x_coord);
        
        legend_strings{patient_iterator} = table.NameMaps{1}(patient_uid);
    end
    
    [y_tick_spacing, min_y, max_y] = PTKGraphUtilities.GetOptimalTickSpacing(min_y, max_y);
    
    y_ticks = min_y : y_tick_spacing : max_y;
    
    % Draw lines for each context
    for x_tick_index = 1 : numel(x_ticks)
        x_tick = x_ticks(x_tick_index);
        context_line_colour = x_ticks_color_map(x_tick);
        
        h_line = line('Parent', axes_handle, 'XData', [x_tick, x_tick], 'YData', [min_y, max_y], 'Color', context_line_colour{1}, 'LineStyle', ':', 'LineWidth', context_line_width);
        set(get(get(h_line,'Annotation'),'LegendInformation'), 'IconDisplayStyle','off'); % Exclude line from legend
        
        y_offset_ticklabel = abs(max_y - min_y)/60;
        context_label = x_ticks_label_map(x_tick);
        text(x_tick, min_y - y_offset_ticklabel, context_label{1}, 'FontSize', x_tick_label_size, 'clipping', 'off', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Color', context_line_colour{1});
    end
    
    % Set the axes
    ylabel(axes_handle, y_label, 'FontName', font_name, 'FontSize', label_font_size);
    set(gca, 'XTick', [])
    set(gca, 'XTickLabel', '');
    set(gca, 'YTick', y_ticks, 'FontSize', y_tick_label_size)
    axis([0 max_x min_y max_y]);
    
    % Now draw the plots
    for patient_iterator = 1 : number_of_subjects
        plots_info = plots{patient_iterator};
        plot(axes_handle, plots_info.X, plots_info.Y, plots_info.Symbol, 'LineWidth', marker_line_width, 'MarkerEdgeColor', plots_info.Colour, 'Color', plots_info.Colour, 'MarkerSize', marker_size, 'MarkerFaceColor', plots_info.MarkerFaceColour);
    end
    
    if ~isempty(right_lung_segments_label_position) && ~isempty(left_lung_segments_label_position)
        y_offset = abs(max_y - min_y)/15;
        text(right_lung_segments_label_position, min_y - y_offset, 'Right lung', 'FontSize', x_lung_label_size, 'clipping', 'off', 'HorizontalAlignment', 'center', 'Color', right_lung_colour);
        text(left_lung_segments_label_position, min_y - y_offset, 'Left lung', 'FontSize', x_lung_label_size, 'clipping', 'off', 'HorizontalAlignment', 'center', 'Color', left_lung_colour);
    end
    
    
    
    % Create the legend
    legend_handle = legend(legend_strings, 'FontName', font_name, 'FontSize', legend_font_size, 'Location', 'NorthEast');
    legend_children = get(legend_handle, 'Children');
    for child = legend_children'
        if strcmp(get(child, 'Type'), 'line')
            if ~strcmp(get(child, 'Marker'), 'none')
                set(child, 'MarkerSize', legend_marker_size);
            end
        end
    end
end


function sorted_contexts = SortContexts(contexts)
    contexts_as_chars = [];
    for context = contexts
        contexts_as_chars{end + 1} = char(context);
    end
    contexts = contexts_as_chars;
    sorted_contexts = [];
    last_context_was_null = true;
    for context_set = GetContextLabels
        context = context_set{1};
        
        % We use null as a separator between groups of contexts
        if isempty(context)
            if ~last_context_was_null
                sorted_contexts{end + 1} = [];
                sorted_contexts{end + 1} = [];
            end
            last_context_was_null = true;
        else
            char_context = char(context);
            if ismember(char_context, contexts)
                sorted_contexts{end + 1} = char_context;
                contexts = setdiff(contexts, char_context);
                last_context_was_null = false;
            end
        end
    end
    sorted_contexts = [sorted_contexts, contexts];
end

function context_labels = GetContextLabels
    context_labels = {
        PTKContext.Lungs, PTKContext.RightLung, PTKContext.LeftLung, [], ...
        PTKContext.RightUpperLobe, PTKContext.RightMiddleLobe, PTKContext.RightLowerLobe, [], ...
        PTKContext.LeftUpperLobe, PTKContext.LeftLowerLobe, [], ...
        PTKContext.R_AP, PTKContext.R_P, PTKContext.R_AN, ... % Right upper lobe
        PTKContext.R_L, PTKContext.R_M, ... % Right middle lobe
        PTKContext.R_S, PTKContext.R_AB, PTKContext.R_LB, PTKContext.R_MB, PTKContext.R_PB, [], ... % Right lower lobe
        PTKContext.L_APP, PTKContext.L_APP2, PTKContext.L_AN, ... % Upper left lobe
        PTKContext.L_SL, PTKContext.L_IL, ... % Lingular of upper left lobe
        PTKContext.L_S, PTKContext.L_AMB, PTKContext.L_PB, PTKContext.L_LB}; % lower left lobe
end
