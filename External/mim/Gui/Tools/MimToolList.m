classdef MimToolList < handle
    % MimToolList. Stores a list of MimTools
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties (SetAccess = private)
        Tools % Map of tools
    end
    
    properties (Access = private)
        ToolCallback
        ViewerPanel
        
        CineTool
        WindowLevelTool
        ZoomTool
        PanTool
        PanMatlabTool
        Rotate3dMatlabTool
        ZoomMatlabTool
        EditTool
        ReplaceColourTool
        MapColourTool
        MarkerPointTool
    end
    
    methods
        function obj = MimToolList(marker_manager, tool_callback, viewer_panel, image_parameters, image_display_parameters)
            obj.ToolCallback = tool_callback;
            obj.ViewerPanel = viewer_panel;
            
            obj.CineTool = MimCineTool(image_parameters, tool_callback);
            obj.WindowLevelTool = MimWindowLevelTool(image_display_parameters, tool_callback);
            obj.ZoomTool = MimZoomTool(tool_callback);
            obj.PanTool = MimPanTool(tool_callback);
            obj.PanMatlabTool = MimPanMatlabTool(tool_callback);
            obj.Rotate3dMatlabTool = MimRotate3dMatlabTool(tool_callback);
            obj.ZoomMatlabTool = MimZoomMatlabTool(tool_callback);
            obj.EditTool = MimEditManager(obj.ViewerPanel);
            obj.ReplaceColourTool = MimReplaceColourTool(obj.ViewerPanel);
            obj.MapColourTool = MimMapColourTool(obj.ViewerPanel);
            obj.MarkerPointTool = MimMarkerPointTool(marker_manager, obj.ViewerPanel);
           
            tool_list = {obj.ZoomMatlabTool, obj.PanMatlabTool, obj.Rotate3dMatlabTool, obj.MarkerPointTool, obj.WindowLevelTool, obj.CineTool, obj.EditTool, obj.ReplaceColourTool, obj.MapColourTool};

            obj.Tools = containers.Map;
            for tool_set = tool_list
                tool = tool_set{1};
                tag = tool.Tag;
                obj.Tools(tag) = tool;
            end            
        end
        
        function tool = GetCurrentToolForSelectedControl(obj, mouse_is_down, keyboard_modifier)
            
            tool = obj.GetCurrentTool(mouse_is_down, keyboard_modifier, obj.ViewerPanel.SelectedControl);
        end
                
        function tool = GetCurrentTool(obj, mouse_is_down, keyboard_modifier, selected_control)
            if ~isempty(keyboard_modifier) && ~isempty(mouse_is_down) && mouse_is_down
                if strcmp(keyboard_modifier, 'extend')
                    tool = obj.PanTool;
                    return;
                elseif strcmp(keyboard_modifier, 'alt')
                    tool = obj.ZoomTool;
                    return;
                end
            end
            tool = obj.Tools(selected_control);
        end
        
        function tool = GetTool(obj, tag)
            tool = obj.Tools(tag);
        end
        
        function UpdateTools(obj)
            tool_list = obj.Tools.values;
            
            % Disable inactive tools before enabling new tools
            for tool_set = tool_list
                tool = tool_set{1};
                if ~strcmp(obj.ViewerPanel.SelectedControl, tool.Tag);
                    tool.Enable(false);
                end
            end
            
            % Enable tools
            for tool_set = tool_list
                tool = tool_set{1};
                if strcmp(obj.ViewerPanel.SelectedControl, tool.Tag);
                    tool.Enable(true);
                    obj.ToolCallback.GetAxes.SetContextMenu(tool.GetContextMenu);
                end
            end
        end
        
        function input_has_been_processed = ShortcutKeys(obj, key, selected_control)
            % Each tool has a shortcut key to select it
            for tool = obj.Tools.values
                if strcmpi(key, tool{1}.ShortcutKey)
                    obj.ViewerPanel.SetControl(tool{1}.Tag);
                    input_has_been_processed = true;
                    return
                end
            end
            
            % Otherwise let the currently selected tool process shortcuts
            input_has_been_processed = obj.Tools(selected_control).Keypressed(key);
        end
        
        
        function ImageChanged(obj)
            tool = obj.GetCurrentPrimaryTool;
            if ~isempty(tool) && tool.Enabled
                tool.ImageChanged;
            end
        end

        function NewOrientation(obj)
            tool = obj.GetCurrentPrimaryTool;
            if ~isempty(tool) && tool.Enabled
                tool.NewOrientation;
            end
        end
            
        function OverlayImageChanged(obj)
            tool = obj.GetCurrentPrimaryTool;
            if ~isempty(tool) && tool.Enabled
                tool.OverlayImageChanged;
            end
        end
        
        function NewSlice(obj)
            tool = obj.GetCurrentPrimaryTool;
            if ~isempty(tool) && tool.Enabled
                tool.NewSlice;
            end
        end
        
    end
    
    methods (Access = private)
        function tool = GetCurrentPrimaryTool(obj)
            selected_control = obj.ViewerPanel.SelectedControl;
            if obj.Tools.isKey(selected_control)
                tool = obj.Tools(selected_control);
            else
                tool = [];
            end
        end
    end
end

