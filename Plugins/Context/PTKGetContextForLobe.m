classdef PTKGetContextForLobe < PTKPlugin
    % PTKGetContextForLobe. Plugin for finding the region of interest for a lobe.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKGetContextForLobe runs the plugin PTKLeftAndRightLungs to segment
    %     the left and right lungs, then calls the library function
    %     PTKGetLobeROI to extract the region of interest for the required lobe.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Lobe<BR>ROI'
        ToolTip = 'Fetches the ROI for a lobe context'
        Category = 'Context'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        Context = PTKContextSet.Lobe
        PluginType = 'ReplaceImage'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            lobe_mask = dataset.GetResult('PTKLobes', PTKContext.LungROI);
            results = PTKGetLobeROI(lobe_mask, context, reporting);
        end
    end
end