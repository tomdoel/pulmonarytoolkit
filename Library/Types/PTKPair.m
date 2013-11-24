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
    end
end

