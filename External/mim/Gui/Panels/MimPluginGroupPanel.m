classdef MimPluginGroupPanel < GemPanel
    % MimPluginGroupPanel. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimPluginGroupPanel is a panel containing a group of Plugin buttons
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        CachedMinY
        CachedMaxY
    end
    
    properties (Access = private)
        CachedPanelHeight
        CachedPanelWidth
        
        Category
        CurrentCategoryMap
        PluginButtonHandlesMap
        LoadManualSegmentationCallback;
    end
    
    methods
        function obj = MimPluginGroupPanel(parent, category, current_category_map, load_manual_segmentation_callback)
            obj = obj@GemPanel(parent);
            obj.LoadManualSegmentationCallback = load_manual_segmentation_callback;
            obj.Enabled = false;
            
            obj.Category = category;
            obj.CurrentCategoryMap = current_category_map;
            
            obj.AddPlugins(current_category_map);
        end
        
        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemPanel(obj, position);
            set(obj.GraphicalComponentHandle, 'Title', obj.Category, 'BorderType', 'etchedin');
        end
        
        function Resize(obj, new_position)
            Resize@GemPanel(obj, new_position);
            width = new_position(3);
            if isempty(obj.CachedPanelHeight) || (width ~= obj.CachedPanelWidth)
                obj.ResizePanel(width);
            end
        end
        
        function height = GetRequestedHeight(obj, width)
            if isempty(obj.CachedPanelHeight) || (width ~= obj.CachedPanelWidth)
                obj.ResizePanel(width);
            end
            height = obj.CachedPanelHeight;
        end
        
        function AddPlugins(obj, category_map)
            obj.CachedPanelHeight = [];
            obj.CachedPanelWidth = [];
            obj.PluginButtonHandlesMap = containers.Map();
            
            % Add the buttons to the panel
            for current_plugin_key = category_map.keys
                current_plugin = category_map(char(current_plugin_key));
                
                if isempty(current_plugin)
                    button_handle = MimSegmentationButton(obj, current_plugin_key{1}, obj.LoadManualSegmentationCallback);
                else
                    callback_function_handle = @current_plugin.RunPlugin;
                    button_handle = MimPluginButton(obj, callback_function_handle, current_plugin);
                end
                obj.AddChild(button_handle);
                
                obj.PluginButtonHandlesMap(char(current_plugin_key)) = button_handle;
            end
        end
        
        
        function UpdateForNewImage(obj, preview_fetcher, window, level)
            % Refresh the preview images for every button using the supplied dataset
            
            for button = obj.PluginButtonHandlesMap.values
                button{1}.AddPreviewImage(preview_fetcher, window, level);
            end
        end
        
        function plugin_found = AddPreviewImage(obj, plugin_name, preview_fetcher, window, level)
            % Refresh the preview image for the specified plugin
            
            plugin_found = obj.PluginButtonHandlesMap.isKey(plugin_name);
            if plugin_found
                plugin_button = obj.PluginButtonHandlesMap(plugin_name);
                plugin_button.AddPreviewImage(preview_fetcher, window, level);
            end
        end
    end
    
    methods (Access = private)
        function ResizePanel(obj, panel_width)
            
            category_map = obj.CurrentCategoryMap;
            button_spacing_w = 10;
            button_spacing_h = 5;
            header_height = 20;
            footer_height = 10;
            left_right_margins = 10;
            
            max_x = panel_width;
            position_x = left_right_margins;
            position_y = 0;
            
            last_y_coordinate = 0;
            row_height = 0;
            
            % Determine coordinates of buttons and the required panel size
            for current_plugin_key = category_map.keys
                current_plugin = category_map(char(current_plugin_key));
                
                button_handle = obj.PluginButtonHandlesMap(char(current_plugin_key));
                button_width = button_handle.ButtonWidth;
                button_height = button_handle.ButtonHeight;
                                
                current_plugin.ParsedPluginInfo.X = position_x;
                current_plugin.ParsedPluginInfo.Y = position_y;
                current_plugin.ParsedPluginInfo.W = button_width;
                current_plugin.ParsedPluginInfo.H = button_height;
                
                last_y_coordinate = position_y;
                row_height = max(row_height, button_height);
                last_row_height = row_height;
                
                category_map(char(current_plugin_key)) = current_plugin;
                
                position_x = position_x + button_spacing_w + button_width;
                if (position_x + button_width) > (max_x - button_spacing_w)
                    position_y = position_y + button_spacing_h + row_height;
                    position_x = left_right_margins;
                    row_height = 0;
                end
                
            end
            
            obj.CachedPanelHeight = last_y_coordinate + last_row_height + header_height + footer_height;
            obj.CachedPanelWidth = panel_width;
            
            % Resize the buttons
            for current_plugin_key = category_map.keys
                current_plugin = category_map(char(current_plugin_key));
                
                position_x = current_plugin.ParsedPluginInfo.X;
                button_width = current_plugin.ParsedPluginInfo.W;
                button_height = current_plugin.ParsedPluginInfo.H;
                position_y = obj.CachedPanelHeight - button_height - header_height - current_plugin.ParsedPluginInfo.Y;
                
                new_position = [position_x, position_y, button_width, button_height];
                
                button_handle = obj.PluginButtonHandlesMap(char(current_plugin_key));
                button_handle.Resize(new_position);
            end
        end
    end
end