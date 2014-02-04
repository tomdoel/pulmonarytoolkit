function figure_handle = PTKGraphContextVsMetric(table, metric, context_list)
    % PTKGraphContextVsMetric.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    y_label = table.NameMaps{2}(metric);
    
    if nargin < 3 || isempty(context_list)
        context_list = table.IndexMaps{3}.keys;
    end
    
    context_list = SortContexts(context_list);
    
    metrix_index = table.IndexMaps{2}(metric);
    
    
    
    
    number_of_subjects = table.IndexMaps{1}.Count;
    
    colours = {[0, 0, 1], [1, 0, 0], [0, 0, 0], [0, 0.7, 0], [0.7, 0, 0.7], [0, 0.7, 0.7]};
    while numel(colours) < number_of_subjects
        colours = [colours, colours];
    end
    
    symbols = {'d', 's', 'o', 'p', 'h', '^', '*', 'v', '+'};
    while numel(symbols) < number_of_subjects
        symbols = [symbols, symbols];
    end
    
    label_font_size = 10;

    x_tick_label_size = 10;
    if numel(context_list) > 10
        x_tick_label_size = 5;
    end
    
    
    legend_font_size = 9;
    widthheightratio = 4/3;
    page_width_cm = 13;
    font_name = PTKSoftwareInfo.GraphFont;
    marker_line_width = 1;
    marker_size = 8;
    
    legend_strings = {};
    
    patient_uids = table.NameMaps{1}.keys;
    
    max_y = 0;
    min_y = [];

    context_labels = {};
    
    for context_list_index = 1 : numel(context_list)
        if ~isempty(context_list{context_list_index})
            context_labels{end + 1} = table.NameMaps{3}(char(context_list{context_list_index}));
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
    
    for patient_iterator = 1 : number_of_subjects
        patient_uid = patient_uids{patient_iterator};
        patient_index = table.IndexMaps{1}(patient_uid);
        
        x_coords = [];
        y_coords = [];
        
        x_coord = 1;
        
        for context_list_index = 1 : numel(context_list)
            if ~isempty(context_list{context_list_index})
                context_table_index = table.IndexMaps{3}(char(context_list(context_list_index)));
                result = table.ResultsTable{patient_index, metrix_index, context_table_index, :};
                if ~isempty(result)
                    x_coords(end + 1) = x_coord;
                    x_ticks = union(x_ticks, x_coord);
                    y_coords(end + 1) = result;
                end
            end
            x_coord = x_coord + 1;            
        end
        
        colour = colours{patient_iterator};
        symbol = symbols{patient_iterator};
        plot(axes_handle, x_coords, y_coords, symbol, 'LineWidth', marker_line_width, 'MarkerEdgeColor', colour, 'Color', colour, 'MarkerSize', marker_size, 'MarkerFaceColor', min(1, colour + 0.5));

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
    
    y_tick_spacing = PTKGraphUtilities.GetOptimalTickSpacing(min_y, max_y);
    
    

    min_y = y_tick_spacing*floor(min_y/y_tick_spacing);
    y_ticks = min_y : y_tick_spacing : max_y;
        
    % Create the legend
    legend(legend_strings, 'FontName', font_name, 'FontSize', legend_font_size, 'Location', 'NorthEast');
    
    % Set the axes
    set(gca, 'XTick', x_ticks)
    set(gca, 'XTickLabel', context_labels, 'FontSize', x_tick_label_size);
    set(gca, 'YTick', y_ticks)
    ylabel(axes_handle, y_label, 'FontName', font_name, 'FontSize', label_font_size);
    axis([0 max_x min_y max_y]);
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
