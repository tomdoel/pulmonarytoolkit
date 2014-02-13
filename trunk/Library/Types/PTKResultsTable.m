classdef PTKResultsTable < handle
    % PTKResultsTable.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Constant)
        PatientDim = 1
        MetricDim = 2
        ContextDim = 3
        SliceNumberDim = 4
    end
    
    properties
        Titles
    end

    properties (SetAccess = private)
        ResultsTable     % Stores the values in a cell array
        
        IndexMaps        % Maps variable ids to indices of the cell array
        NameMaps         % Maps variable ids to user visible names
    end
    
    methods
        function obj = PTKResultsTable
            obj.IndexMaps = [];
            obj.NameMaps = [];
            
            obj.IndexMaps{obj.PatientDim} = containers.Map;
            obj.IndexMaps{obj.MetricDim} = containers.Map;
            obj.IndexMaps{obj.ContextDim} = containers.Map;
            obj.IndexMaps{obj.SliceNumberDim} = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
            
            obj.NameMaps{obj.PatientDim} = containers.Map;
            obj.NameMaps{obj.MetricDim} = containers.Map;
            obj.NameMaps{obj.ContextDim} = containers.Map;
            obj.NameMaps{obj.SliceNumberDim} = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
        end
        
        function AddCell(obj, patient_name, metric_name, context, slice_number, value, reporting)
            new_value = false;
            if ~obj.IndexMaps{obj.PatientDim}.isKey(patient_name)
                obj.IndexMaps{obj.PatientDim}(patient_name) = obj.IndexMaps{obj.PatientDim}.Count + 1;
                new_value = true;
            end
            if ~obj.IndexMaps{obj.MetricDim}.isKey(metric_name)
                obj.IndexMaps{obj.MetricDim}(metric_name) = obj.IndexMaps{obj.MetricDim}.Count + 1;
                new_value = true;
            end
            if ~obj.IndexMaps{obj.ContextDim}.isKey(context)
                obj.IndexMaps{obj.ContextDim}(context) = obj.IndexMaps{obj.ContextDim}.Count + 1;
                new_value = true;
            end
            if ~obj.IndexMaps{obj.SliceNumberDim}.isKey(slice_number)
                obj.IndexMaps{obj.SliceNumberDim}(slice_number) = obj.IndexMaps{obj.SliceNumberDim}.Count + 1;
                new_value = true;
            end
            patient_index = obj.IndexMaps{obj.PatientDim}(patient_name);
            metric_index = obj.IndexMaps{obj.MetricDim}(metric_name);
            context_index = obj.IndexMaps{obj.ContextDim}(context);
            slice_number_index = obj.IndexMaps{obj.SliceNumberDim}(slice_number);
            
            if ~new_value
                current_value = obj.ResultsTable{patient_index, metric_index, context_index, slice_number_index};
                if ~isempty(current_value)
                    reporting.ShowWarning('PTKResultsTable:ValueBeingOverwritten', 'The value you are adding overwrites an existing value', []);
                end
            end
            
            obj.ResultsTable{patient_index, metric_index, context_index, slice_number_index} = value;
        end
        
        
        function AddMetricName(obj, name, user_visible_name)
            obj.NameMaps{obj.MetricDim}(name) = user_visible_name;
        end
        
        function AddContextName(obj, name, user_visible_name)
            obj.NameMaps{obj.ContextDim}(name) = user_visible_name;
        end
        
        function AddPatientName(obj, name, user_visible_name)
            obj.NameMaps{obj.PatientDim}(name) = user_visible_name;
        end
        
        function AddSliceName(obj, name, user_visible_name)
            obj.NameMaps{obj.SliceNumberDim}(uint32(name)) = user_visible_name;
        end
        
        
    end
end

