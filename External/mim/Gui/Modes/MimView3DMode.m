classdef MimView3DMode < handle
    % MimView3DMode. Part of the internal gui for the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the TD MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (SetObservable)
        Flags
    end
    
    properties (SetAccess = private)
        AllowAutomaticModeEntry = false % Determines whether the mode can be entered automatically when the dataset or result is changed
        ExitOnNewPlugin = true % Mode will exit if a new plugin result is called
    end
    
    properties (Access = private)
        AppDef
        ViewerPanel
        GuiDataset
        Settings
        Reporting
        
        Dataset
        PluginName
        VisiblePluginName
        Context
        PluginInfo
    end
    
    methods
        function obj = MimView3DMode(viewer_panel, gui_dataset, app_def, settings, reporting)
            obj.ViewerPanel = viewer_panel;
            obj.GuiDataset = gui_dataset;
            obj.AppDef = app_def;
            obj.Settings = settings;
            obj.Reporting = reporting;
        end
        
        function EnterMode(obj, current_dataset, plugin_info, current_plugin_name, current_visible_plugin_name, current_context, current_segmentation_name)
            obj.Context = current_context;
            obj.Dataset = current_dataset;
            obj.PluginInfo = plugin_info;
            obj.PluginName = current_plugin_name;
            obj.VisiblePluginName = current_visible_plugin_name;

            if ~isempty(plugin_info)
                obj.ViewerPanel.SetModes(MimModes.View3DMode, []);
            end
        end
        
        function sub_mode = GetSubModeName(obj)
            sub_mode = obj.ViewerPanel.SubMode;
        end
        
        function ExitMode(obj)
            obj.Dataset = [];
            obj.PluginName = [];
            obj.VisiblePluginName = [];
            obj.Context = [];
        end

        function OverlayImageChanged(obj, ~, ~)
            obj.ViewerPanel.ClearRenderAxes;
            obj.ViewerPanel.SetModes([], []);
        end
        
        function MarkOverlayAsUnchanged(obj)
        end        
    end
end