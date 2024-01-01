classdef CoreErrorUtilities < handle
    % Error-related utility functions.
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    methods (Static)
        
        % Obtain the name of the function which signalled the error (useful in
        % error reporting)
        function [calling_function, stack] = GetCallingFunction(levels_to_ignore)
            caller_found = false;
            max_levels = 10;
            calling_function = [];
            
            while ~caller_found
                % Get the call stack, excluding the call to this function and the
                % caller of this function
                [stack, ~] = dbstack(levels_to_ignore, '-completenames');
                if isempty(stack)
                    caller_found = true;
                else
                    stack_top = stack(1);
                    calling_function = stack_top.name;
                    if length(calling_function) < 11 || ~strcmp(calling_function(1:11), 'CoreReporting')
                        caller_found = true;
                    end
                    levels_to_ignore = levels_to_ignore + 1;
                end
            end
        end
        
        function ThrowException(id, message)
            [stack, ~] = dbstack(2, '-completenames');
            
            msgStruct = [];
            msgStruct.message = message;
            msgStruct.identifier = id;
            msgStruct.stack = stack;
            error(msgStruct);
        end
    end
end

