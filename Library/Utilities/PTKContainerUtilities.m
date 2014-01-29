classdef PTKContainerUtilities
    % PTKContainerUtilities. Utility functions related to data storage classes
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods (Static)

        function field_values = GetFieldValuesFromSet(set, field_name)
            % Returns a set of values, corresponding to the contents of the field
            % 'field_name' in each structure in the set 'set'.
            if isempty(set)
                field_values = [];
                return;
            end
            field_values = cellfun(@(x)getfield(x, field_name), set, 'UniformOutput', false); %#ok<GFLD>
        end
        
        function field_values = GetMatrixOfFieldValuesFromSet(set, field_name)
            % Returns a matrix of values, corresponding to the contents of the field
            % 'field_name' in each structure in the set 'set'.
            if isempty(set)
                field_values = [];
                return;
            end
            field_values = cell2mat(PTKContainerUtilities.GetFieldValuesFromSet(set, field_name));
        end
        
        function values_set = ConvertToSet(values)
            % Converts the input values to a set of values, while preserving strings.
            % If values is already a set, this does nothing. Otherwise, values is
            % converted into a cell array. However, character arrays (ie strings)
            % are converted into a cell array containing one string
            if iscell(values)
                values_set = values;
            elseif ischar(values)
                values_set = {values};
            else
                values_set = num2cell(values);
            end
        end
        
        function cell_array = CellEmptyToNan(cell_array)
            % Converts empty cells to NaN, enabling conversion of cell arrays to matrices without loss of empty elements
            
            empty = cellfun(@isempty, cell_array);
            cell_array(empty) = {NaN};
            
        end
        
        function value_array = GetMatrixOfPropertyValues(object_list, property_name, value_for_nulls)
            % Gets an array of property values from the object array, converting any empty
            % values into the parameter value_for_nulls
            
            value_array = {object_list.(property_name)};
            empty_value = cellfun(@isempty, value_array);
            if any(empty_value)
                value_array(empty_value) = {value_for_nulls};
            end
            value_array = cell2mat(value_array);
        end
    end
end

