classdef PTKOriginalImage < PTKPlugin
    % PTKOriginalImage. Plugin to obtain hte uncropped full-size image
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            reporting.ShowProgress('Loading Images');
            results = PTKLoadImages(dataset.GetImageInfo, reporting);
            reporting.CompleteProgress;
        end
    end
end