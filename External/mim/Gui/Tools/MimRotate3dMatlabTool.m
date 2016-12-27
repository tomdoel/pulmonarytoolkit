classdef MimRotate3dMatlabTool < MimTool
    % MimRotate3dMatlabTool. A tool for invoking the Matlab pan tool with MimViewerPanel
    %
    %     MimRotate3dMatlabTool is a tool class used with MimViewerPanel to allow the user
    %     to use Matlab's rotate3d tool.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties
        ButtonText = 'Rot'
        Cursor = 'arrow'
        ToolTip = 'Rotate in 3D tool'
        Tag = 'Rotate'
        ShortcutKey = 'r'
    end
    
    properties (Access = private)
        Callback
    end
    
    methods
        function obj = MimRotate3dMatlabTool(callback)
            obj.Callback = callback;
        end
        
        function Enter(obj)
            obj.Callback.EnableRotate3d(true);
        end
        
        function Exit(obj)
            obj.Callback.EnableRotate3d(false);
        end
    end
end

