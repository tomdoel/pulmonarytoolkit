classdef PTKGetContextForOriginalImage < PTKPlugin
    % PTKGetContextForOriginalImage. Plugin for fetching a template for the
    %     original loaded image before any cropping or resizing
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKGetContextForOriginalImage calls PTKOriginalImage to get the region of interest
    %     for the lung. An empty template image is returned.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Context for Full Lung'
        ToolTip = 'Change the context to display the full lung'
        Category = 'Context'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        Context = PTKContextSet.OriginalImage
        PluginType = 'ReplaceImage'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, ~, ~)
            results = dataset.GetResult('PTKOriginalImage').BlankCopy;
        end
    end
end