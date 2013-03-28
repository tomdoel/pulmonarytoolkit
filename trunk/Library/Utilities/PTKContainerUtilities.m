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
            field_values = cellfun(@(x)getfield(x, field_name), set, 'UniformOutput', false); %#ok<GFLD>
        end
        
        % Returns a matrix of values, corresponding to the contents of the field
        % 'field_name' in each structure in the set 'set'.
        function field_values = GetMatrixOfFieldValuesFromSet(set, field_name)
            field_values = cell2mat(PTKContainerUtilities.GetFieldValuesFromSet(set, field_name));
        end
        
    end
end

