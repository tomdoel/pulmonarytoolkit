classdef CoreEventData < event.EventData
    % CoreEventData. Encapsulate data to be passed when an event occurs.
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
    %         notify(obj, 'MouseClick', CoreEventData(coords));
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        Data
    end
    
    methods
        function obj = CoreEventData(data)
            obj.Data = data;
        end
    end
end