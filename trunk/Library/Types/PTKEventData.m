classdef PTKEventData < event.EventData
    % PTKEventData. Encapsulate data to be passed when an event occurs.
    %
    %     Use this class when you trigger an event which needs to provide data
    %     to its listeners.
    %
    %     Example
    %     -------
    %
    %     This example triggers a MouseClick event and passes the image coordiates
    %
    %         coords = GetImageCoordinates;
    %         notify(obj, 'MouseClick', PTKEventData(coords));
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        Data
    end
    
    methods
        function obj = PTKEventData(data)
            obj.Data = data;
        end
    end
end