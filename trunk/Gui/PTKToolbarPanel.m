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
        ButtonGroups
        OrderedButtonGroupList
        GuiApp
        OrganisedPlugins
        ToolMap
        ToolbarLine
    end
    
    properties (Constant)
        ToolbarHeight = 100
        LeftBorder = 10
        LeftMargin = 10
        HorizontalSpacing = 10
    end
    
    methods
        function obj = PTKToolbarPanel(parent, organised_plugins, gui_app, settings, reporting)
            obj = obj@PTKPanel(parent, reporting);
            
            obj.GuiApp = gui_app;
            obj.ButtonGroups = containers.Map;
            obj.OrderedButtonGroupList = {};
            obj.ToolMap = containers.Map;
            obj.OrganisedPlugins = organised_plugins;
            
            obj.ToolbarLine = PTKLineAxes(obj, 'top');
            obj.ToolbarLine.SetLimits([1, 1], [1, 1]);
            obj.AddChild(obj.ToolbarLine, obj.Reporting);            
            
            obj.AddTools;
        end
        
        function Resize(obj, new_position)
            Resize@PTKPanel(obj, new_position);

            obj.ToolbarLine.Resize([1, 1, new_position(3), new_position(4)]);
            
            toolbar_position = new_position;
            toolbar_position(4) = max(1, toolbar_position(4) - 3);
            
            
            x_position = obj.LeftMargin;
            for tool_group = obj.OrderedButtonGroupList
                tool_group_panel = tool_group{1};
                panel_height = tool_group_panel.GetRequestedHeight;
                y_position = max(0, toolbar_position(2) + round((toolbar_position(4) - panel_height)/2));
                if tool_group_panel.Enabled
                    tool_group_panel.Resize([x_position, y_position, tool_group_panel.GetWidth, panel_height]);
                    x_position = x_position + obj.HorizontalSpacing + tool_group_panel.GetWidth;
                end
            end
        end
        
        function Update(obj, gui_app)
            % Calls each group panel and updates the buttons. In some cases, buttons will
            % become enabled that were previously disabled; this requires the position
            % (since this may not have been set if this is the first time the button has been made visible)
            
            for tool_group = obj.OrderedButtonGroupList
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
        
    end
    
    methods (Access = private)
        function AddTools(obj)
            tools = obj.OrganisedPlugins.GetOrderedPlugins('Toolbar');
            for tool = tools
                obj.AddTool(tool{1}.PluginObject);
            end
        end
        
        function AddTool(obj, tool)
            tool_name = class(tool);
            category_key = tool.Category;
            if ~obj.ButtonGroups.isKey(category_key)
                new_group = PTKLabelButtonGroup(obj, category_key, '', category_key, obj.Reporting);
                obj.ButtonGroups(category_key) = new_group;
                obj.OrderedButtonGroupList{end + 1} = new_group;
                obj.AddChild(new_group, obj.Reporting);
            end
            if isprop(tool, 'Icon')
                icon = imread(fullfile(PTKSoftwareInfo.IconFolder, tool.Icon));
            else
                icon = [];
            end
            tool_group = obj.ButtonGroups(category_key);
            new_button = PTKToolButton(obj, tool, icon, obj.GuiApp, obj.Reporting);
            tool_group.AddButton(new_button, obj.Reporting);
            tool_struct = [];
            tool_struct.Button = new_button;
            tool_struct.ToolObject = tool;
            obj.ToolMap(tool_name) = tool_struct;
        end
    end
end