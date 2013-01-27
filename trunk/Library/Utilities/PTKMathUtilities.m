classdef PTKMathUtilities
    % PTKMathUtilities. Utility functions related to maths
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    methods (Static)

        % Returns a particular combination of n values chosen from the row vector v, with
        % replacement.
        function combination = GetParticularCombination(v, n, combination_number)
            combination = zeros(1, n);
            for index = n : -1 : 1
                combination(index) = v(1 + rem(combination_number - 1, numel(v)));
                combination_number = 1 + fix((combination_number - 1)/numel(v));
            end
            
        end
        
        % Returns all combinations of n values chosen from the row vector v, with
        % replacement
        function all_combinations = GetAllCombinations(v, n)
            if n == 1
                all_combinations = v';
            else
                remaining_values = PTKMathUtilities.GetAllCombinations(v, n - 1);
                numels = size(remaining_values, 1);
                all_combinations = [v(ceil((1:numels*numel(v))/numels))', repmat(remaining_values, length(v), 1)];
            end
        end
        
        % Returns true if all the entries of the matrix are integers (even if
        % the underlying data type is a float)
        function is_integer = IsMatrixInteger(matrix_to_check)
           is_integer = ~any(mod(matrix_to_check, 1));
        end
        
    end
end

