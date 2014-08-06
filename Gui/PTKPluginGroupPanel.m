classdef PTKPluginGroupPanel < PTKPanel
    % PTKPluginGroupPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPluginGroupPanel is a panel containing a group of Plugin buttons
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
        
    end
    
    methods
        function obj = PTKPluginGroupPanel(parent, category, current_category_map, callback_function_handle, reporting)
            obj = obj@PTKPanel(parent, reporting);
            obj.Enabled = false;
            
            obj.Category = category;
            obj.CurrentCategoryMap = current_category_map;
            
            obj.AddPlugins(current_category_map, callback_function_handle);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKPanel(obj, position, reporting);
            set(obj.GraphicalComponentHandle, 'Title', obj.Category, 'BorderType', 'etchedin');
        end
        
        function Resize(obj, new_position)
            Resize@PTKPanel(obj, new_position);
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
        
        function AddPlugins(obj, category_map, callback_function_handle)
            obj.CachedPanelHeight = [];
            obj.CachedPanelWidth = [];
            obj.PluginButtonHandlesMap = containers.Map;
            
            % Add the buttons to the panel
            for current_plugin_key = category_map.keys
                current_plugin = category_map(char(current_plugin_key));
                
                button_handle = PTKPluginButton(obj, callback_function_handle, current_plugin);
                obj.AddChild(button_handle, obj.Reporting);
                
                obj.PluginButtonHandlesMap(char(current_plugin_key)) = button_handle;
            end
        end
        
        
        function AddAllPreviewImagesToButtons(obj, current_dataset, window, level)
            % Refresh the preview images for every button using the supplied dataset
            
            for button = obj.PluginButtonHandlesMap.values
                button{1}.AddPreviewImage(current_dataset, window, level);
            end
        end
        
        function plugin_found = AddPreviewImage(obj, plugin_name, current_dataset, window, level)
            % Refresh the preview image for the specified plugin
            
            plugin_found = obj.PluginButtonHandlesMap.isKey(plugin_name);
            if plugin_found
                plugin_button = obj.PluginButtonHandlesMap(plugin_name);
                plugin_button.AddPreviewImage(current_dataset, window, level);
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
                                
                current_plugin.X = position_x;
                current_plugin.Y = position_y;
                current_plugin.W = button_width;
                current_plugin.H = button_height;
                
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
                
                position_x = current_plugin.X;
                button_width = current_plugin.W;
                button_height = current_plugin.H;
                position_y = obj.CachedPanelHeight - button_height - header_height - current_plugin.Y;
                
                new_position = [position_x, position_y, button_width, button_height];
                
                button_handle = obj.PluginButtonHandlesMap(char(current_plugin_key));
                button_handle.Resize(new_position);
            end
        end
    end
end