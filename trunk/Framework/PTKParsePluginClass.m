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
    
    if strcmp(plugin_class.PTKVersion, '1')
        reporting.ShowWarning('PTKPluginInformation:OldPluginVersion', ['Plugin ' plugin_name ' uses an old version of the plugin interface. This may be deprecated in a future version of this software.'], []);
    elseif ~strcmp(plugin_class.PTKVersion, PTKSoftwareInfo.PTKVersion)
        reporting.ShowWarning('PTKPluginInformation:MismatchingPluginVersion', ['Plugin ' plugin_name ' was created for a more recent version of this software'], []);
    end
    
    new_plugin.ToolTip = plugin_class.ToolTip;
    new_plugin.AlwaysRunPlugin = plugin_class.AlwaysRunPlugin;
    new_plugin.AllowResultsToBeCached = plugin_class.AllowResultsToBeCached;
    new_plugin.PluginType = plugin_class.PluginType;
    new_plugin.ButtonText = plugin_class.ButtonText;
    new_plugin.Category = plugin_class.Category;
    new_plugin.HidePluginInDisplay = plugin_class.HidePluginInDisplay;
    new_plugin.ButtonWidth = plugin_class.ButtonWidth;
    new_plugin.ButtonHeight = plugin_class.ButtonHeight;
    new_plugin.PTKVersion = plugin_class.PTKVersion;
    new_plugin.GeneratePreview = plugin_class.GeneratePreview;
    new_plugin.FlattenPreviewImage = plugin_class.FlattenPreviewImage;
    
    if isfield(plugin_class, 'Context')
        new_plugin.Context = plugin_class.Context;
    else
        new_plugin.Context = [];
    end
end
