function new_plugin = PTKParseGuiPluginClass(plugin_name, plugin_class, reporting)
    % PTKParseGuiPluginClass. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Fetches information about any GUI plugins for the Pulmonary Toolkit which
    %     are available.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    new_plugin = [];
    new_plugin.PluginName = plugin_name;
    
    new_plugin.ToolTip = plugin_class.ToolTip;
    new_plugin.ButtonText = plugin_class.ButtonText;
    if ~isempty(plugin_class.Category)
        new_plugin.Category = plugin_class.Category;
    else
        new_plugin.Category = [];
    end
    new_plugin.HidePluginInDisplay = plugin_class.HidePluginInDisplay;
    new_plugin.ButtonWidth = plugin_class.ButtonWidth;
    new_plugin.ButtonHeight = plugin_class.ButtonHeight;
    new_plugin.AlwaysRunPlugin = false; % Ensures plugin name is not in italics
    
    if isprop(plugin_class, 'Visibility')
        new_plugin.Visibility = plugin_class.Visibility;
    end
    
    if isprop(plugin_class, 'Mode')
        new_plugin.Mode = plugin_class.Mode;
    else
        new_plugin.Mode = [];
    end
    
    if isprop(plugin_class, 'SubMode')
        new_plugin.SubMode = plugin_class.SubMode;
    else
        new_plugin.SubMode = [];
    end
end
