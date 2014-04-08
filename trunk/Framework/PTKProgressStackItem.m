classdef PTKProgressStackItem < handle
    % PTKProgressStackItem. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     PTKProgressStackItem is part of the mechanism used to nest progress
    %     reporting, so that for example, if an operation is performed 4 times,
    %     the progress bar will not go from 0 to 100% 3 times, but instead go
    %     from 0 to 25% for the first operation, etc.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ProgressText
        MinPosition
        MaxPosition
        LastProgressValue
        Visible
    end
    
    methods
        function obj = PTKProgressStackItem(text, min_pos, max_pos)
            if nargin > 0
                obj.ProgressText = text;
                obj.MinPosition = min_pos;
                obj.MaxPosition = max_pos;
                obj.LastProgressValue = 0;
            end
            obj.Visible = false;
        end
    end
end

