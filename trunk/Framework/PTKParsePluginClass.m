function new_plugin = PTKParsePluginClass(plugin_name, plugin_class, suggested_category, reporting)
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
        
    new_plugin = struct;
    new_plugin.PluginName = plugin_name;

    
    new_plugin.ToolTip = plugin_class.ToolTip;
    new_plugin.AlwaysRunPlugin = plugin_class.AlwaysRunPlugin;
    new_plugin.AllowResultsToBeCached = plugin_class.AllowResultsToBeCached;
    new_plugin.PluginType = plugin_class.PluginType;
    new_plugin.ButtonText = plugin_class.ButtonText;
    
    if ~isempty(plugin_class.Category)
        new_plugin.Category = plugin_class.Category;
    else
        if ~isempty(suggested_category)
            new_plugin.Category = suggested_category;
        else
            new_plugin.Category = PTKSoftwareInfo.DefaultCategoryName;
        end
    end
    
    new_plugin.HidePluginInDisplay = plugin_class.HidePluginInDisplay;
    new_plugin.ButtonWidth = plugin_class.ButtonWidth;
    new_plugin.ButtonHeight = plugin_class.ButtonHeight;
    new_plugin.PTKVersion = plugin_class.PTKVersion;
    new_plugin.GeneratePreview = plugin_class.GeneratePreview;
    new_plugin.FlattenPreviewImage = plugin_class.FlattenPreviewImage;
    
    property_list = properties(plugin_class);
    if ismember('Context', property_list);
        new_plugin.Context = plugin_class.Context;
    else
        new_plugin.Context = [];
    end
    
    if ismember('Mode', property_list) && ~isempty(plugin_class.Mode);
        new_plugin.Mode = plugin_class.Mode;
    else
        new_plugin.Mode = PTKSoftwareInfo.DefaultMode;
    end
    
    if ismember('EnableModes', property_list);
        new_plugin.EnableModes = plugin_class.EnableModes;
    else
        new_plugin.EnableModes = {};
    end
    
    if ismember('SubMode', property_list);
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
