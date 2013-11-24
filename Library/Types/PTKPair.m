classdef PTKPair < handle
    % PTKPair. A class for storing two values
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        First
        Second
    end
    
    methods 
        function obj = PTKPair(first, second)
            obj.First = first;
            obj.Second = second;
        end
        
        function first = FirstList(obj)
            first = {obj.First};
        end

        function first = SecondList(obj)
            first = {obj.First};
        end
        
        % Equality operator
        function is_equal = eq(obj, other)
            if ~isa(other, 'PTKPair')
                is_equal = false;
            else
                is_equal = isequal(obj.First, other.First) && isequal(obj.Second, other.Second);
            end
        end
        
    end
end

