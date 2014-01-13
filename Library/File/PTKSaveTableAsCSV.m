function PTKSaveTableAsCSV(file_path, file_name, table, file_dim, row_dim, col_dim, filters, reporting)
    % PTKSaveTableAsCSV.
    %
    %     filters is used to filter each of the four dimensions of patient name,
    %     metric name, context name and slice number
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       

    other_dim = setdiff([1,2,3,4], [file_dim, row_dim, col_dim]);
    if numel(other_dim) ~= 1
        reporting.Error('PTKSaveTableAsCSV:InvalidArguments', 'You must specify a unique dimension for each of the files, rows and columns');
    end
    
    ranges = [];
    names = [];
    
    if isempty(filters)
        filters = {[], [], [], []};
    end
    
    % Use the supplied filters for considering specific patients, metrics, etc.
    for filter_index = 1 : 4
        filter = filters{filter_index};
        if isempty(filter)
            filters{filter_index} = Sort(table.IndexMaps{filter_index}.keys, filter_index);
        end
    end
    
    for filter_index = 1 : 4
        filter = filters{filter_index};    
        names_filter = [];
        ranges_filter = [];
        for name = filter
            names_filter{end + 1} = table.NameMaps{filter_index}(name{1});
            ranges_filter{end + 1} = table.IndexMaps{filter_index}(name{1});
        end
        ranges{filter_index} = ranges_filter;
        names{filter_index} = names_filter;
    end
    
    file_range = ranges{file_dim};
    row_range = ranges{row_dim};
    col_range = ranges{col_dim};
    other_range = ranges{other_dim};
    
    if numel(other_range) ~= 1
       reporting.Error('PTKSaveTableAsCSV:InvalidArguments', 'The unused dimension must have a size of 1 after filtering'); 
    end
    
    % Get column labels
    label_line = table.Titles{row_dim};
    for col_range_index = 1 : numel(col_range)
        col_name = names{col_dim}(col_range_index);
        label = col_name{1};
        label_line = [label_line, ',' label];
    end
    
    
    for file_range_set = file_range
        file_range_value = file_range_set{1};
        file_appendix = names{file_dim}(file_range_value);
        file_appendix = file_appendix{1};
        
        text_file_writer = PTKTextFileWriter(file_path, [file_name '_' file_appendix '.csv'], reporting);
        
        text_file_writer.WriteLine(label_line);
        
        for row_range_index = 1 : numel(row_range)
            row_range_value = row_range{row_range_index};
            row_name = names{row_dim}(row_range_index);
            col_text = row_name{1};
            
            for col_range_set = col_range
                
                col_range_value = col_range_set{1};
                
                [pi, mi, ci, si] = GetIndices(file_range_value, row_range_value, col_range_value, file_dim, row_dim, col_dim, other_dim);
                cell_value = table.ResultsTable{pi, mi, ci, si};
                if isnumeric(cell_value)
                    cell_value_string = num2str(cell_value, '%5.2f');
                else
                    cell_value_string = char(cell_value);
                end
                col_text = [col_text, ',', cell_value_string];
            end
            
            % Write line to text file
            text_file_writer.WriteLine(col_text);
        end
        text_file_writer.Close;
    end
end

function [pi, mi, ci, si] = GetIndices(file_range_value, row_range_value, col_range_value, file_dim, row_dim, col_dim, other_dim)
    table_indices = [0, 0, 0, 0];
    table_indices(file_dim) = file_range_value;
    table_indices(row_dim) = row_range_value;
    table_indices(col_dim) = col_range_value;
    table_indices(other_dim) = 1;
    pi = table_indices(1);
    mi = table_indices(2);
    ci = table_indices(3);
    si = table_indices(4);
end
    
function sorted_values = Sort(values_to_sort, filter_index)
    sorted_values = [];
    if filter_index == 3
        for context = GetContextLabels
            char_context = char(context);
            if ismember(char_context, values_to_sort)
                sorted_values{end + 1} = char_context;
                values_to_sort = setdiff(values_to_sort, char_context);
            end
        end
        sorted_values = [sorted_values, values_to_sort];
    else
        sorted_values = values_to_sort;
    end
end

function context_labels = GetContextLabels
    context_labels = [
        PTKContext.Lungs, PTKContext.RightLung, PTKContext.LeftLung, ...
        PTKContext.RightUpperLobe, PTKContext.RightMiddleLobe, PTKContext.RightLowerLobe, ...
        PTKContext.LeftUpperLobe, PTKContext.LeftLowerLobe, ...
        PTKContext.R_AP, PTKContext.R_P, PTKContext.R_AN, ...
        PTKContext.R_L, PTKContext.R_M, PTKContext.R_S, ...
        PTKContext.R_MB, PTKContext.R_AB, PTKContext.R_LB, ...
        PTKContext.R_PB, PTKContext.L_APP, PTKContext.L_APP2, ...
        PTKContext.L_AN, PTKContext.L_SL, PTKContext.L_IL, ...
        PTKContext.L_S, PTKContext.L_AMB, PTKContext.L_LB, PTKContext.L_PB];    
end
