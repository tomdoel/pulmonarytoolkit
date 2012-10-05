classdef TDErrorUtilities < handle
    % TDErrorUtilities. Error-related utility functions.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods (Static)
        
        % Obtain the name of the function which signalled the error (useful in
        % error reporting)
        function [calling_function, stack] = GetCallingFunction(levels_to_ignore)
            caller_found = false;
            max_levels = 10;
            
            while ~caller_found
                % Get the call stack, excluding the call to this function and the
                % caller of this function
                [stack, ~] = dbstack(levels_to_ignore, '-completenames');
                stack_top = stack(1);
                calling_function = stack_top.name;
                if length(calling_function) < 11 || ~strcmp(calling_function(1:11), 'TDReporting')
                    caller_found = true;
                end
                levels_to_ignore = levels_to_ignore + 1;
            end
        end
    end
end

