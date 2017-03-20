function new_plugin = MimParseGuiPluginClass(plugin_name, plugin_class, suggested_category, default_category, default_mode, reporting)
    % MimParseGuiPluginClass. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %     Fetches information about any GUI plugins for the TD MIM Toolkit which
    %     are available.
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    new_plugin = [];
    new_plugin.PluginName = plugin_name;
    
    new_plugin.ToolTip = plugin_class.ToolTip;
    new_plugin.ButtonText = plugin_class.ButtonText;
    if ~isempty(plugin_class.Category)
        new_plugin.Category = plugin_class.Category;
    else
        if ~isempty(suggested_category)
            new_plugin.Category = suggested_category;
        else
            new_plugin.Category = default_category;
        end
    end
    new_plugin.HidePluginInDisplay = plugin_class.HidePluginInDisplay;
    new_plugin.ButtonWidth = plugin_class.ButtonWidth;
    new_plugin.ButtonHeight = plugin_class.ButtonHeight;
    new_plugin.AlwaysRunPlugin = false; % Ensures plugin name is not in italics
    
    property_list = properties(plugin_class);
    
    if ismember('Visibility', property_list)
        new_plugin.Visibility = plugin_class.Visibility;
    end
    
    if ismember('Mode', property_list) && ~isempty(plugin_class.Mode)
        new_plugin.Mode = plugin_class.Mode;
    else
        new_plugin.Mode = default_mode;
    end
    
    if ismember('SubMode', property_list)
        new_plugin.SubMode = plugin_class.SubMode;
    else
        new_plugin.SubMode = [];
    end
    
    if ismember('Location', property_list);
        new_plugin.Location = plugin_class.Location;
    else
        new_plugin.Location = 100;
    end    
end
