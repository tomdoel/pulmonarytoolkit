classdef PTKPanMatlabTool < PTKTool
    % PTKPanMatlabTool. A tool for invoking the Matlab pan tool with PTKViewerPanel
    %
    %     PTKPanMatlabTool is a tool class used with PTKViewerPanel to allow the user
    %     to use Matlab's pan tool.
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
        Cursor = 'arrow'
        RestoreKeyPressCallbackWhenSelected = true
        ToolTip = 'Pan tool'
        Tag = 'Pan'
        ShortcutKey = 'p'
    end
    
    properties (Access = private)
        Callback
    end
    
    methods
        function obj = PTKPanMatlabTool(callback)
            obj.Callback = callback;
        end
        
        function Enter(obj)
            obj.Callback.EnablePan(true);
        end
        
        function Exit(obj)
            obj.Callback.EnablePan(false);
        end
    end
end

