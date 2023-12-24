classdef MimZoomMatlabTool < MimTool
    % MimZoomMatlabTool. A tool for invoking the Matlab zoom tool with MimViewerPanel
    %
    %     MimZoomMatlabTool is a tool class used with MimViewerPanel to allow the user
    %     to use Matlab's zoom tool.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    properties
        ButtonText = 'Zoom'
        Cursor = 'arrow'
        ToolTip = 'Zoom tool'
        Tag = 'Zoom'
        ShortcutKey = 'z'
    end
    
    properties (Access = private)    
        Callback
    end
    
    methods
        function obj = MimZoomMatlabTool(callback)
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

