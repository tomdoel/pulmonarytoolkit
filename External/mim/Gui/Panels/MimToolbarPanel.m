classdef MimToolbarPanel < GemPanel
    % MimToolbarPanel. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimToolbarPanel represents a panel containing tool controls that
    %     are enabled and disabled dynamically
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        ControlGroups
        ControlGroupSeparators
        OrderedControlGroupList
        GuiApp
        ModeTabName
        ModeToSwitchTo
        OrganisedPlugins
        ToolMap
        AppDef
        Visibility
        GroupVertically
        AllowWrapping
    end
    
    properties (Constant)
        ToolbarHeight = 85
        RowHeight = 85
        LeftMargin = 10
        RightMargin = 20
        HorizontalSpacing = 10
    end
    
    methods
        function obj = MimToolbarPanel(parent, organised_plugins, mode_tab_name, mode_to_switch_to, visibility, gui_app, app_def, group_vertically, allow_wrapping)
            obj = obj@GemPanel(parent);
            
            obj.ModeTabName = mode_tab_name;
            obj.ModeToSwitchTo = mode_to_switch_to;
            obj.Visibility = visibility;
            obj.TopBorder = ~group_vertically;
            obj.AppDef = app_def;
            obj.GuiApp = gui_app;
            obj.ControlGroups = containers.Map;
            obj.ControlGroupSeparators = containers.Map;
            obj.OrderedControlGroupList = {};
            obj.ToolMap = containers.Map;
            obj.OrganisedPlugins = organised_plugins;
            obj.GroupVertically = group_vertically;
            obj.AllowWrapping = allow_wrapping;
            
            obj.AddTools();
        end
        
        function Resize(obj, new_position)
            Resize@GemPanel(obj, new_position);
 
            % After calling Resize@GemPanel, the position will have been adjusted due to the border
            new_position = obj.InnerPosition;            
            
            panel_height = max(1, new_position(4));
            row_height = obj.RowHeight;
            panel_top = new_position(2) + panel_height;
            y_column_top = panel_top;
            y_column_base = y_column_top - row_height;
            
            min_x = 1 + obj.LeftMargin;
            max_x = new_position(3) - obj.RightMargin;
            x_position = min_x;
            is_first_separator = true;
            
            for tool_group_key = obj.OrderedControlGroupList
                tool_group_panel = obj.ControlGroups(tool_group_key{1});
                
                if tool_group_panel.Enabled
                    group_panel_height = tool_group_panel.GetRequestedHeight;
                    group_panel_width = tool_group_panel.GetWidth;
                    
                    if (obj.AllowWrapping) && (x_position > min_x) && (obj.GroupVertically || (x_position + group_panel_width > max_x))
                        x_position = min_x;
                        y_column_top = y_column_top - row_height;
                        y_column_base = y_column_top - row_height;
                    end
                    
                    if obj.GroupVertically
                        separator = obj.ControlGroupSeparators(tool_group_key{1});
                        y_position = max(1, y_column_top - separator.GetRequestedHeight);
                        if is_first_separator
                            is_first_separator = false;
                            separator.TopBorder = false;
                        else
                            separator.TopBorder = true;
                        end
                        separator.Enable;
                        separator.Resize([1, y_position, new_position(3), separator.GetRequestedHeight]);
                        y_column_top = y_column_top - separator.GetRequestedHeight;
                        y_column_base = y_column_top - row_height;
                    end
                
                    
                    y_offset = round((row_height - group_panel_height)/2);
                    y_position = max(1, y_column_base + y_offset);
                    tool_group_panel.Resize([x_position, y_position, group_panel_width, group_panel_height]);
                    x_position = x_position + obj.HorizontalSpacing + group_panel_width;
                    
                else
                    if obj.GroupVertically
                        separator = obj.ControlGroupSeparators(tool_group_key{1});
                        separator.Disable;
                    end
                end 
            end
        end
        
        function Update(obj, gui_app)
            % Calls each group panel and updates the controls. In some cases, controls will
            % become enabled that were previously disabled; this requires the position
            % (since this may not have been set if this is the first time the control has been made visible)
            
            for tool_group_key = obj.OrderedControlGroupList
                tool_group_panel = obj.ControlGroups(tool_group_key{1});
                tool_group_panel.Update(gui_app);
            end
            
            if ~isempty(obj.Position)
                obj.Resize(obj.Position);
            end
            
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.ToolbarHeight;
        end
        
        function mode = GetModeTabName(obj)
            mode = obj.ModeTabName;
        end
        
        function visibility = GetVisibility(obj)
            visibility = obj.Visibility;
        end
        
        function mode = GetModeToSwitchTo(obj)
            mode = obj.ModeToSwitchTo;
        end
        
        function AddPlugins(obj, current_dataset)
        end
        
        function UpdateForNewImage(obj, current_dataset, window, level)
        end
        
        function AddPreviewImage(obj, plugin_name, preview_fetcher, window, level)
        end

        function RefreshPlugins(obj, current_dataset, window, level)
        end
        
    end
    
    methods (Access = private)
        function AddTools(obj)
            tools = obj.OrganisedPlugins.GetOrderedPlugins(obj.ModeTabName);
            for tool = tools
                obj.AddTool(tool{1}.PluginObject);
            end
        end
        
        function AddTool(obj, tool)
            tool_name = class(tool);
            category_key = tool.Category;
            if ~obj.ControlGroups.isKey(category_key)
                new_group = GemLabelButtonGroup(obj, category_key, '', category_key);
                obj.ControlGroups(category_key) = new_group;
                obj.OrderedControlGroupList{end + 1} = category_key;
                obj.AddChild(new_group);
                
                if obj.GroupVertically
                    separator = GemSeparator(obj, category_key);
                    obj.ControlGroupSeparators(category_key) = separator;
                    obj.AddChild(separator);
                end
            end
            icon_found = false;
            
            if isprop(tool, 'Icon')
                icons_paths = obj.AppDef.GetIconsFolders;
                for icon_path = icons_paths
                    if CoreDiskUtilities.FileExists(icon_path{1}, tool.Icon)
                        icon = imread(fullfile(icon_path{1}, tool.Icon));
                        icon_found = true;
                        break;
                    end
                end
            end
                
            if ~icon_found
                icon = imread(obj.AppDef.GetDefaultPluginIcon);
            end

            % IconColour overrides greyscale
            if isprop(tool, 'IconColour')
                size_icon = size(icon);
                icon = double(icon/255);
                icon_bw = repmat(0.21*icon(:,:,1) + 0.72*icon(:,:,2) + 0.07*icon(:,:,3), [1,1,3]);
                colour_tint = repmat(shiftdim(double(tool.IconColour), -1), [size_icon(1:2), 1]);
                icon = uint8(255*colour_tint.*icon_bw);
            elseif obj.AppDef.ForceGreyscale
                icon = repmat(0.21*icon(:,:,1) + 0.72*icon(:,:,2) + 0.07*icon(:,:,3), [1,1,3]);
            end
            
            tool_group = obj.ControlGroups(category_key);
            if isa(tool, 'MimGuiPluginSlider')
                new_control = MimPluginLabelSlider(obj, tool, icon, obj.GuiApp);
                new_control.StackVertically = tool.StackVertically;
            elseif isa(tool, 'MimGuiPluginEditBox')
                new_control = MimPluginLabelEditBox(obj, tool, icon, obj.GuiApp);
                new_control.StackVertically = tool.StackVertically;
            else
                new_control = MimPluginLabelButton(obj, tool, icon, obj.GuiApp);
                new_control.ButtonWidth = 8*tool.ButtonWidth;
            end
            tool_group.AddControl(new_control);
            tool_struct = [];
            tool_struct.Control = new_control;
            tool_struct.ToolObject = tool;
            obj.ToolMap(tool_name) = tool_struct;
        end
    end
end