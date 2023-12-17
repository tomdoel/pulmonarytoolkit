classdef CoreStack < handle
    % CoreStack. A class for storing values on a stack
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        Stack
    end
    
    methods 
        function obj = CoreStack(stack_items)
            if nargin > 0
                obj.Stack = CoreContainerUtilities.ConvertToSet(stack_items);
            else
                obj.Stack = {};
            end
        end
        
        function Push(obj, stack_items)
            % Places one or more items on the stack. stack_items can be a single
            % object, a set or an array of objects
            obj.Stack = [obj.Stack CoreContainerUtilities.ConvertToSet(stack_items)];
        end
        
        function item = Pop(obj)
            % Retrieves the item from the top of the stack
            item = obj.Stack{end};
            obj.Stack(end) = [];
        end
        
        function is_empty = IsEmpty(obj)
            % Returns true if there are no items in the stack
            is_empty = isempty(obj.Stack);
        end
        
        function all_values = GetAndClear(obj)
            % Clears the stack and returns any remaining values in a set
            all_values = obj.Stack;
            obj.Stack = [];
        end
        
        function field_values = GetField(obj, field_name)
            % Returns the values of the field field_name from every item in the
            % stack
            field_values = CoreContainerUtilities.GetFieldValuesFromSet(obj.Stack, field_name);
        end
    end
end
