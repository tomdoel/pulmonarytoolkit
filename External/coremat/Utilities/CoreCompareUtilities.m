classdef CoreCompareUtilities
    % CoreCompareUtilities. Utility functions related to comparing of types
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    methods (Static)

        function is_equal = CompareEnumName(value_1, value_2)
            % Returns true if a string or enumeration value has the same
            % character value as another string or enumeration value.
            % Returns true if the names of the enumerations match, even if 
            % the unerlying enumeration types are different.
            % Returns false if the provided types are not strings or
            % enumerations
            if isnumeric(value_1) || isstruct(value_1) || isnumeric(value_2) || isstruct(value_2)
                is_equal = false;
                return;
            end
            is_equal = strcmp(char(value_1), char(value_2));
        end
    end
end

