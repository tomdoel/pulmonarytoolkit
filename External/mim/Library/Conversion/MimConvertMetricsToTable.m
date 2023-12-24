function results_table = MimConvertMetricsToTable(results, patient_name, patient_id, reporting, context_mapping_function, results_table)
    % MimConvertMetricsToTable.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %       
   
    if nargin < 6 || isempty(results_table)
        results_table = MimResultsTable();
    end
    AddToTable(results_table, results, patient_id, context_mapping_function, reporting);
    results_table.AddPatientName(patient_id, patient_name);
end

function AddToTable(table, results, patient_id, context_mapping_function, reporting)
    
    table.Titles{MimResultsTable.ContextDim} = 'Region';
    table.Titles{MimResultsTable.MetricDim} = 'Measurement';
    table.Titles{MimResultsTable.SliceNumberDim} = 'Slice Number';
    table.Titles{MimResultsTable.PatientDim} = 'Patient';
    
    field_map = GetFieldMap(results, table, context_mapping_function);
    
    for field = field_map.keys
        context_name = field{1};
        slice_map = GetSliceMap(field_map(context_name), table);
        for slice = slice_map.keys
            slice_name = slice{1};
            metric_object = slice_map(slice_name);
            metric_names = metric_object.GetListOfMetrics;
            for metric_name_set = metric_names'
                if ~isempty(metric_name_set)
                    metric_name = metric_name_set{1};
                    value = metric_object.(metric_name);
                    table.AddCell(patient_id, metric_name, context_name, slice_name, value, reporting);
                    table.AddMetricName(metric_name, metric_object.MetricNameMap(metric_name));
                end
            end
        end
    end
end

function field_map = GetFieldMap(results, table, context_mapping_function)
    field_map = containers.Map();
    if isstruct(results)
        field_names = fieldnames(results);
        for field_name_set = field_names'
            field_name = field_name_set{1};
            field_map(field_name) = results.(field_name);
            visible_field_name = context_mapping_function(field_name);
            table.AddContextName(field_name, visible_field_name);
        end  
    else
        visible_field_name = context_mapping_function('');
        table.AddContextName('', visible_field_name);
        field_map('') = results;
    end
end

function slice_map = GetSliceMap(results, table)
    slice_map = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    for index = 1 : numel(results)
        slice_name = uint32(index);
        slice_name_text = int2str(index);
        slice_map(slice_name) = results(index);
        table.AddSliceName(index, slice_name_text);
    end
end
