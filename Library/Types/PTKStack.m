classdef PTKStack < handle
    % PTKStack. A class for storing values on a stack
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        Stack
    end
    
    methods 
        function obj = PTKStack(stack_items)
            if nargin > 0
                obj.Stack = PTKContainerUtilities.ConvertToSet(stack_items);
            else
                obj.Stack = cell.empty;
            end
        end
        
        function Push(obj, stack_items)
            obj.Stack = [obj.Stack PTKContainerUtilities.ConvertToSet(stack_items)];
        end
        
        function item = Pop(obj)
            item = obj.Stack{end};
            obj.Stack(end) = [];
        end
        
        function is_empty = IsEmpty(obj)
            is_empty = isempty(obj.Stack);
        end
        
        % Clears the stack and returns any remaining values in a set
        function all_values = GetAndClear(obj)
            all_values = obj.Stack;
            obj.Stack = [];
        end
        
        function field_values = GetField(obj, field_name)
             field_values = PTKContainerUtilities.GetFieldValuesFromSet(obj.Stack, field_name);
        end
    end
end