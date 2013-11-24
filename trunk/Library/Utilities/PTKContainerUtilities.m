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

        % Returns a set of values, corresponding to the contents of the field
        % 'field_name' in each structure in the set 'set'.
        function field_values = GetFieldValuesFromSet(set, field_name)
            if isempty(set)
                field_values = [];
                return;
            end
            field_values = cellfun(@(x)getfield(x, field_name), set, 'UniformOutput', false); %#ok<GFLD>
        end
        
        % Returns a matrix of values, corresponding to the contents of the field
        % 'field_name' in each structure in the set 'set'.
        function field_values = GetMatrixOfFieldValuesFromSet(set, field_name)
            if isempty(set)
                field_values = [];
                return;
            end
            field_values = cell2mat(PTKContainerUtilities.GetFieldValuesFromSet(set, field_name));
        end
        
        % Converts the input values to a set of values, while preserving
        % strings.
        % If values is already a set, this does nothing. Otherwise, values is
        % converted into a cell array. However, character arrays (ie strings)
        % are converted into a cell array containing one string
        function values_set = ConvertToSet(values)
            if iscell(values)
                values_set = values;
            elseif ischar(values)
                values_set = {values};
            else
                values_set = num2cell(values);
            end
        end
    end
end

