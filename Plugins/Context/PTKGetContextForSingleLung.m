classdef PTKGetContextForSingleLung < PTKPlugin
    % PTKGetContextForSingleLung. Plugin for finding the region of interest for the left or right lung.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKGetContextForSingleLung runs the plugin PTKLeftAndRightLungs to segment
    %     the left and right lungs, then calls the library function
    %     PTKGetLungROIFromLeftAndRightLungs to extract the region of interest
    %     for the left or right lung
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Single Lung <BR>ROI'
        ToolTip = 'Change the context to display the left lung'
        Category = 'Context'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        Context = PTKContextSet.SingleLung
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
            left_and_right_lung_mask = dataset.GetResult('PTKLeftAndRightLungs', PTKContext.LungROI);
            results = PTKGetLungROIFromLeftAndRightLungs(left_and_right_lung_mask, context, reporting);
        end
    end
end