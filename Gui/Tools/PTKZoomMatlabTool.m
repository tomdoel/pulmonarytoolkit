classdef PTKZoomMatlabTool < PTKTool
    % PTKZoomMatlabTool. A tool for invoking the Matlab zoom tool with PTKViewerPanel
    %
    %     PTKZoomMatlabTool is a tool class used with PTKViewerPanel to allow the user
    %     to use Matlab's zoom tool.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Zoom'
        Cursor = 'arrow'
        RestoreKeyPressCallbackWhenSelected = true
        ToolTip = 'Zoom tool'
        Tag = 'Zoom'
        ShortcutKey = 'z'
    end
    
    properties (Access = private)    
        Callback
    end
    
    methods
        function obj = PTKZoomMatlabTool(callback)
            obj.Callback = callback;
        end
 
        function Enter(obj)
            obj.Callback.EnableZoom(true);
        end
        
        function Exit(obj)
            obj.Callback.EnableZoom(false);
        end  
    end
    
end

