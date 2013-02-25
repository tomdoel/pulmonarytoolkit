classdef PTKTest < handle
    % PTKTest. Part of the PTK test framework
    %
    % PTKTest is the base class for tests.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
    end
    
    methods
        function Assert(obj, condition, message)
            if ~condition
                PTKErrorUtilities.ThrowException('PTKTest:AssertonFailure', ...
                    ['Assertion failure: ' message]);
                
            end
        end
    end
end

