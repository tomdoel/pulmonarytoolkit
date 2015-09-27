classdef CorePair < handle
    % CorePair. A class for storing two values
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        First
        Second
    end
    
    methods 
        function obj = CorePair(first, second)
            obj.First = first;
            obj.Second = second;
        end
        
        function first = FirstList(obj)
            first = {obj.First};
        end

        function first = SecondList(obj)
            first = {obj.First};
        end
        
        function is_equal = eq(obj, other)
            % Equality operator
            
            if ~isa(other, 'CorePair')
                is_equal = false;
            else
                is_equal = isequal(obj.First, other.First) && isequal(obj.Second, other.Second);
            end
        end
        
    end
end

