classdef PTKPanTool < PTKTool
    % PTKPanTool. A tool for interactively panning an image with PTKViewerPanel
    %
    %     PTKPanTool is a tool class used with PTKViewerPanel to allow the user
    %     to pan an image using mouse and keyboard controls.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Pan'
        Cursor = 'hand'
        RestoreKeyPressCallbackWhenSelected = false
        ToolTip = 'Pan tool'
        Tag = 'Pan'
        ShortcutKey = ''
    end
    
    properties (Access = private)
        Callback
    end
    
    methods
        function obj = PTKPanTool(callback)
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

