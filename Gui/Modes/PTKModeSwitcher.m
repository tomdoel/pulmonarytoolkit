classdef PTKModeSwitcher < handle
    % PTKModeSwitcher. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        CurrentMode
        CurrentModeString
    end
    
    properties (Access = private)
        ViewerPanel
        Modes
        OverlayImageChangedListener
    end
    
    methods
        function obj = PTKModeSwitcher(viewer_panel, gui_dataset, settings, reporting)
            obj.ViewerPanel = viewer_panel;
            obj.OverlayImageChangedListener = addlistener(viewer_panel, 'OverlayImageChangedEvent', @obj.OverlayImageChanged);
            obj.Modes = containers.Map;
            obj.Modes(PTKModes.EditMode) = PTKEditMode(viewer_panel, gui_dataset, settings, reporting);
            obj.CurrentMode = [];
            obj.CurrentModeString = [];
        end
        
        function delete(obj)
            delete(obj.OverlayImageChangedListener);
        end
        
        function SwitchMode(obj, mode, current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context)
            if ~isempty(obj.CurrentMode)
                obj.CurrentMode.ExitMode;
            end
            obj.CurrentModeString = mode;
            if isempty(mode)
                obj.CurrentMode = [];
            else
                obj.CurrentMode = obj.Modes(mode);
                obj.CurrentMode.EnterMode(current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context);
            end
            if isempty(current_plugin_info)
                sub_mode = [];
            else
                sub_mode = current_plugin_info.SubMode;
            end
            obj.ViewerPanel.SetModes(mode, sub_mode);
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
        
        function UpdateMode(obj, current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context)
            if ~isempty(obj.CurrentMode)
                obj.CurrentMode.ExitMode;
                if obj.CurrentMode.AllowAutomaticModeEntry
                    obj.CurrentMode.EnterMode(current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context);
                else
                    obj.SwitchMode([], current_dataset, current_plugin_info, current_plugin_name, current_visible_plugin_name, current_context);
                end
            end
        end
        
        function OverlayImageChanged(obj, ~, ~)
            if ~isempty(obj.CurrentMode)
                obj.CurrentMode.OverlayImageChanged;
            end
        end
    end
end