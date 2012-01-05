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
            
            % Get the call stack, excluding the call to this function and the
            % caller of this function
            [stack, ~] = dbstack(levels_to_ignore, '-completenames');
            stack_top = stack(1);
            calling_function = stack_top.name;
        end
    end
end

