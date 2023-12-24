classdef MimPanTool < MimTool
    % MimPanTool. A tool for interactively panning an image with MimViewerPanel
    %
    %     MimPanTool is a tool class used with MimViewerPanel to allow the user
    %     to pan an image using mouse and keyboard controls.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Pan'
        Cursor = 'hand'
        ToolTip = 'Pan tool'
        Tag = 'Pan'
        ShortcutKey = ''
    end
    
    properties (Access = private)
        Callback
    end
    
    methods
        function obj = MimPanTool(callback)
            obj.Callback = callback;
        end
        
        function MouseDragged(obj, screen_coords, last_coords)
            [min_coords, max_coords] = obj.Callback.GetImageLimits;
            pan_offset = screen_coords - last_coords;
            x_lim = [min_coords(1), max_coords(1)];
            x_lim = x_lim - pan_offset(1);
            y_lim = [min_coords(2), max_coords(2)];
            y_lim = y_lim - pan_offset(2);
            
            obj.Callback.SetImageLimits([x_lim(1), y_lim(1)], [x_lim(2), y_lim(2)]);
        end
    end
    
end

