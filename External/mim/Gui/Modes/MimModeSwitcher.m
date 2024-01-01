classdef MimModeSwitcher < CoreBaseClass
    % MimModeSwitcher. Part of the internal gui for the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the TD MIM Toolkit.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        CurrentMode
        CurrentModeString
    end
    
    properties (Access = private)
        ViewerPanel
        Modes
    end
    
    events
        ModeChangedEvent
    end
    
    methods
        function obj = MimModeSwitcher(viewer_panel, gui_dataset, app_def, settings, reporting)
            obj.ViewerPanel = viewer_panel;
            obj.AddEventListener(viewer_panel.GetOverlayImageSource, 'ImageModified', @obj.OverlayImageChanged);
            obj.Modes = containers.Map();
            obj.Modes(MimModes.EditMode) = MimEditMode(viewer_panel, gui_dataset, app_def, settings, reporting);
            obj.Modes(MimModes.MarkerMode) = MimMarkerMode(viewer_panel, gui_dataset, app_def, settings, reporting);
            obj.Modes(MimModes.View3DMode) = MimView3DMode(viewer_panel, gui_dataset, app_def, settings, reporting);
            obj.CurrentMode = [];
            obj.CurrentModeString = [];
        end
        
        function mode = GetSubModeName(obj)
            if isempty(obj.CurrentMode)
                mode = [];
            else
                mode = obj.CurrentMode.GetSubModeName;
            end
        end
        
        function SwitchMode(obj, mode, current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context, current_segmentation_name)
            if ~strcmp(mode, obj.CurrentModeString)
                if ~isempty(obj.CurrentMode)
                    obj.CurrentMode.ExitMode();
                end
                obj.CurrentModeString = mode;
                if isempty(mode)
                    obj.CurrentMode = [];
                    obj.ViewerPanel.SetModes([], []);
                else
                    obj.CurrentMode = obj.Modes(mode);
                    obj.CurrentMode.EnterMode(current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context, current_segmentation_name);
                end
                notify(obj, 'ModeChangedEvent', CoreEventData(mode));
            end
        end
        
        function ModeAutoSave(obj)
            if ~isempty(obj.CurrentMode)
                obj.CurrentMode.AutoSave();
            end
        end
        
        function PrePluginCall(obj)
            % Called before a new plugin is executed, allowing modes to exit before this
            % happens
            
            if ~isempty(obj.CurrentMode)
                if obj.CurrentMode.ExitOnNewPlugin
                    obj.SwitchMode([], [], [], [], [], []);
                end
            end            
        end
        
        function UpdateCurrentMode(obj, current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context)
            if ~isempty(obj.CurrentMode) 
                obj.CurrentMode.ExitMode();
                if obj.CurrentMode.AllowAutomaticModeEntry
                    obj.CurrentMode.EnterMode(current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context);
                else
                    obj.SwitchMode([], current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context);
                end
            end
        end
        
        function ViewerPanelModeChanged(obj, new_mode, current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context)
            if ~isempty(obj.CurrentMode)
                if obj.CurrentMode.ExitOnViewerPanelModeChanged(new_mode)
                    obj.CurrentMode.ExitMode();
                    obj.SwitchMode([], current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context);
                end
            end
        end
        
        function OverlayImageChanged(obj, ~, ~)
            if ~isempty(obj.CurrentMode)
                obj.CurrentMode.OverlayImageChanged;
            end
        end
        
        function MarkOverlayAsUnchanged(obj)
            if ~isempty(obj.CurrentMode)
                obj.CurrentMode.MarkOverlayAsUnchanged();
            end
        end
    end
end