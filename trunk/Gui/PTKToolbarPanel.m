classdef PTKToolbarPanel < PTKPanel
    % PTKToolbarPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKToolbarPanel represents the toolbar panel along the bottom of the GUI
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        ControlGroups
        OrderedControlGroupList
        GuiApp
        ModeName
        PluginModeName
        OrganisedPlugins
        ToolMap
    end
    
    properties (Constant)
        ToolbarHeight = 85
        RowHeight = 85
        LeftMargin = 10
        RightMargin = 20
        HorizontalSpacing = 10
    end
    
    methods
        function obj = PTKToolbarPanel(parent, organised_plugins, mode_name, plugin_mode_name, gui_app, reporting)
            obj = obj@PTKPanel(parent, reporting);
            
            obj.ModeName = mode_name;
            obj.PluginModeName = plugin_mode_name;
            obj.TopBorder = true;
            
            obj.GuiApp = gui_app;
            obj.ControlGroups = containers.Map;
            obj.OrderedControlGroupList = {};
            obj.ToolMap = containers.Map;
            obj.OrganisedPlugins = organised_plugins;
            
            obj.AddTools;
        end
        
        function Resize(obj, new_position)
            Resize@PTKPanel(obj, new_position);

            panel_height = max(1, new_position(4));
            row_height = obj.RowHeight;
            panel_top = new_position(2) + panel_height;
            y_column_base = panel_top - row_height;
            
            min_x = 1 + obj.LeftMargin;
            max_x = new_position(3) - obj.RightMargin;
            x_position = min_x;
            
            for tool_group = obj.OrderedControlGroupList
                tool_group_panel = tool_group{1};
                group_panel_height = tool_group_panel.GetRequestedHeight;
                group_panel_width = tool_group_panel.GetWidth;
                
                if (x_position > min_x) && (x_position + group_panel_width > max_x)
                    x_position = min_x;
                    y_column_base = y_column_base - row_height;
                end
                
                y_offset = round((row_height - group_panel_height)/2);
                y_position = max(1, y_column_base + y_offset);
                if tool_group_panel.Enabled
                    tool_group_panel.Resize([x_position, y_position, group_panel_width, group_panel_height]);
                    x_position = x_position + obj.HorizontalSpacing + group_panel_width;
                end
            end
        end
        
        function Update(obj, gui_app)
            % Calls each group panel and updates the controls. In some cases, controls will
            % become enabled that were previously disabled; this requires the position
            % (since this may not have been set if this is the first time the control has been made visible)
            
            for tool_group = obj.OrderedControlGroupList
                tool_group_panel = tool_group{1};
                tool_group_panel.Update(gui_app);
            end
            
            if ~isempty(obj.Position)
                obj.Resize(obj.Position);
            end
            
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.ToolbarHeight;
        end
        
        function mode = GetMode(obj)
            mode = obj.PluginModeName;
        end

        function AddPlugins(obj, current_dataset)
        end
        
        function AddAllPreviewImagesToButtons(obj, current_dataset, window, level)
        end
        
        function AddPreviewImage(obj, plugin_name, current_dataset, window, level)
        end

        function RefreshPlugins(obj, current_dataset, window, level)
        end
        
    end
    
    methods (Access = private)
        function AddTools(obj)
            tools = obj.OrganisedPlugins.GetOrderedPlugins(obj.ModeName);
            for tool = tools
                obj.AddTool(tool{1}.PluginObject);
            end
        end
        
        function AddTool(obj, tool)
            tool_name = class(tool);
            category_key = tool.Category;
            if ~obj.ControlGroups.isKey(category_key)
                new_group = PTKLabelButtonGroup(obj, category_key, '', category_key, obj.Reporting);
                obj.ControlGroups(category_key) = new_group;
                obj.OrderedControlGroupList{end + 1} = new_group;
                obj.AddChild(new_group, obj.Reporting);
            end
            if isprop(tool, 'Icon')
                icon = imread(fullfile(PTKDirectories.GetSourceDirectory, PTKSoftwareInfo.IconFolder, tool.Icon));
            else
                icon = imread(fullfile(PTKDirectories.GetSourceDirectory, PTKSoftwareInfo.IconFolder, PTKSoftwareInfo.DefaultPluginIcon));
            end
            tool_group = obj.ControlGroups(category_key);
            if isa(tool, 'PTKGuiPluginSlider')
                new_control = PTKPluginLabelSlider(obj, tool, icon, obj.GuiApp, obj.Reporting);
            else
                new_control = PTKPluginLabelButton(obj, tool, icon, obj.GuiApp, obj.Reporting);
            end
            tool_group.AddControl(new_control, obj.Reporting);
            tool_struct = [];
            tool_struct.Control = new_control;
            tool_struct.ToolObject = tool;
            obj.ToolMap(tool_name) = tool_struct;
        end
    end
end