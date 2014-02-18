classdef PTKUndoStack < handle
    % PTKUndoStack. A class for storing values on a stack, with a maximum number of
    % items
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        Stack
        MaxNumberOfItems
    end
    
    methods 
        function obj = PTKUndoStack(stack_items, max_num_items)
            if nargin > 0
                obj.Stack = PTKContainerUtilities.ConvertToSet(stack_items);
                obj.MaxNumberOfItems = max_num_items;
            else
                obj.Stack = cell.empty;
            end
        end
        
        function Push(obj, stack_items)
            % Places one or more items on the stack. stack_items can be a single
            % object, a set or an array of objects
            obj.Stack = [obj.Stack PTKContainerUtilities.ConvertToSet(stack_items)];
            if numel(obj.Stack) > obj.MaxNumberOfItems
                obj.Stack = obj.Stack(end - obj.MaxNumberOfItems + 1 : end);
            end
        end
        
        function item = Pop(obj)
            % Retrieves the item from the top of the stack
            if isempty(obj.Stack)
                item = [];
            else
                item = obj.Stack{end};
                obj.Stack(end) = [];
            end
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
        
        function Clear(obj)
            % Clears the stack
            obj.Stack = [];
        end
        
        function field_values = GetField(obj, field_name)
            % Returns the values of the field field_name from every item in the
            % stack
            field_values = PTKContainerUtilities.GetFieldValuesFromSet(obj.Stack, field_name);
        end
    end
end