classdef MimMarkerMode < handle
    % MimMarkerMode. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetObservable)
        Flags
    end
    
    properties (SetAccess = private)
        AllowAutomaticModeEntry = false % Determines whether the mode can be entered automatically when the dataset or result is changed
        ExitOnNewPlugin = false % Mode will exit if a new plugin result is called
    end
    
    properties (Access = private)
        AppDef
        ViewerPanel
        GuiDataset
        Settings
        Reporting
    end
    
    methods
        function obj = MimMarkerMode(viewer_panel, gui_dataset, app_def, settings, reporting)
            obj.ViewerPanel = viewer_panel;
            obj.GuiDataset = gui_dataset;
            obj.AppDef = app_def;
            obj.Settings = settings;
            obj.Reporting = reporting;
        end
        
        function EnterMode(obj, current_dataset, plugin_info, current_plugin_name, current_visible_plugin_name, current_context, current_segmentation_name)
            obj.ViewerPanel.SetModes(MimModes.MarkerMode, []);
        end
        
        function sub_mode = GetSubModeName(obj)
            sub_mode = obj.ViewerPanel.SubMode;
        end
        
        function ExitMode(obj)
            obj.ViewerPanel.SetControl('W/L');
        end
        
        function OverlayImageChanged(obj, ~, ~)
        end
    end
end