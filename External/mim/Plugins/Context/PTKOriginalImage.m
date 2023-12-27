classdef PTKOriginalImage < PTKPlugin
    % PTKOriginalImage. Plugin to obtain hte uncropped full-size image
    %
    %     This is a plugin for the TD MIM Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the TD MIM Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKOriginalImage loads the original image data from disk. Since
    %     full-size images can be very large, and plugins normally use the
    %     region of interest, this plugin result is not usually
    %     cached by default.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    
    properties
        ButtonText = 'Full Image'
        ToolTip = 'Change the context to display the complete original image'
        Category = 'Context'

        AllowResultsToBeCached = false
        AlwaysRunPlugin = false
        PluginType = 'ReplaceImage'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Context = PTKContextSet.OriginalImage
        Visibility = 'Developer'
        Version = 3

        MemoryCachePolicy = 'Temporary'
        DiskCachePolicy = 'Off'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            reporting.ShowProgress('Loading Images');
            results = MimLoadImages(dataset.GetImageInfo, reporting);
            reporting.CompleteProgress();
        end
    end
end