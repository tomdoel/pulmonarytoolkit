function new_plugin = PTKParsePluginClass(plugin_name, plugin_class, reporting)
    % PTKParsePluginClass. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Fetches information about any plugins for the Pulmonary Toolkit which
    %     are available. 
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    new_plugin = [];
    new_plugin.PluginName = plugin_name;

    
    new_plugin.ToolTip = plugin_class.ToolTip;
    new_plugin.AlwaysRunPlugin = plugin_class.AlwaysRunPlugin;
    new_plugin.AllowResultsToBeCached = plugin_class.AllowResultsToBeCached;
    new_plugin.PluginType = plugin_class.PluginType;
    new_plugin.ButtonText = plugin_class.ButtonText;
    
    if ~isempty(plugin_class.Category)
        new_plugin.Category = plugin_class.Category;
    else
        new_plugin.Category = [];
    end
    
    new_plugin.HidePluginInDisplay = plugin_class.HidePluginInDisplay;
    new_plugin.ButtonWidth = plugin_class.ButtonWidth;
    new_plugin.ButtonHeight = plugin_class.ButtonHeight;
    new_plugin.PTKVersion = plugin_class.PTKVersion;
    new_plugin.GeneratePreview = plugin_class.GeneratePreview;
    new_plugin.FlattenPreviewImage = plugin_class.FlattenPreviewImage;
    
    if isprop(plugin_class, 'Context')
        new_plugin.Context = plugin_class.Context;
    else
        new_plugin.Context = [];
    end
    
    if isprop(plugin_class, 'Mode')
        new_plugin.Mode = plugin_class.Mode;
    else
        new_plugin.Mode = [];
    end
    
    if isprop(plugin_class, 'EnableModes')
        new_plugin.EnableModes = plugin_class.EnableModes;
    else
        new_plugin.EnableModes = {};
    end
    
    if isprop(plugin_class, 'SubMode')
        new_plugin.SubMode = plugin_class.SubMode;
    else
        new_plugin.SubMode = [];
    end
end
