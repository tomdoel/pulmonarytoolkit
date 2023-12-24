classdef CoreTest < handle
    % Base class for MTest unit tests
    %
    % Unit tests should inherit from this class
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties
    end
    
    methods
        function Assert(obj, condition, message)
            if ~condition
                CoreErrorUtilities.ThrowException('CoreTest:AssertonFailure', ...
                    ['Assertion failure: ' message]);
                
            end
        end
    end
end

