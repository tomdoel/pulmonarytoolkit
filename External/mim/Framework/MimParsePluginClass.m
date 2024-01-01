function new_plugin = MimParsePluginClass(plugin_name, plugin_class, suggested_category, reporting)
    % Fetches information about any plugins for the TD MIM Toolkit which are available. 
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
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
        new_plugin.Category = suggested_category;
    end
    
    new_plugin.HidePluginInDisplay = plugin_class.HidePluginInDisplay;
    new_plugin.ButtonWidth = plugin_class.ButtonWidth;
    new_plugin.ButtonHeight = plugin_class.ButtonHeight;
    
    new_plugin.GeneratePreview = plugin_class.GeneratePreview;
    new_plugin.FlattenPreviewImage = plugin_class.FlattenPreviewImage;
    
    property_list = properties(plugin_class);
    if ismember('PluginInterfaceVersion', property_list)
        new_plugin.PluginInterfaceVersion = plugin_class.PluginInterfaceVersion;
    elseif ismember('PTKVersion', property_list)
        new_plugin.PluginInterfaceVersion = plugin_class.PTKVersion;
    else
        new_plugin.PluginInterfaceVersion = 1;
    end

    if ismember('Context', property_list)
        new_plugin.Context = plugin_class.Context;
    else
        new_plugin.Context = [];
    end
    
    if ismember('Mode', property_list)
        new_plugin.Mode = plugin_class.Mode;
    else
        new_plugin.Mode = [];
    end
    
    if ismember('EnableModes', property_list)
        new_plugin.EnableModes = plugin_class.EnableModes;
    else
        new_plugin.EnableModes = {};
    end
    
    if ismember('SubMode', property_list)
        new_plugin.SubMode = plugin_class.SubMode;
    else
        new_plugin.SubMode = [];
    end
    
    if ismember('Location', property_list)
        new_plugin.Location = plugin_class.Location;
    else
        new_plugin.Location = 100;
    end
    
    if ismember('Version', property_list)
        new_plugin.PluginVersion = plugin_class.Version;
    else
        new_plugin.PluginVersion = 1;
    end
    
    if ismember('MemoryCachePolicy', property_list)
        new_plugin.MemoryCachePolicy = MimCachePolicy.(plugin_class.MemoryCachePolicy);
    else
        new_plugin.MemoryCachePolicy = MimCachePolicy.Off;
    end
    
    if ismember('DiskCachePolicy', property_list)
        new_plugin.DiskCachePolicy = MimCachePolicy.(plugin_class.DiskCachePolicy);
    else
        if new_plugin.AllowResultsToBeCached
            new_plugin.DiskCachePolicy = MimCachePolicy.Permanent;
        else
            new_plugin.DiskCachePolicy = MimCachePolicy.Off;
        end
    end
    
    if ismember('EditRequiresPluginResult', property_list)
        new_plugin.EditRequiresPluginResult = plugin_class.EditRequiresPluginResult;
    else
        new_plugin.EditRequiresPluginResult = false;
    end
    
    if ismember('SuggestManualEditOnFailure', property_list)
        new_plugin.SuggestManualEditOnFailure = plugin_class.SuggestManualEditOnFailure;
    else
        new_plugin.SuggestManualEditOnFailure = false;
    end
end
