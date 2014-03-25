classdef PTKLungRegion < PTKPlugin
    % PTKLungRegion. Plugin for finding the left or right lung region of interest
    % for registration purposes
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Lung Region'
        ToolTip = ''
        Category = 'Context'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceImage'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Context = PTKContextSet.SingleLung
        
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            roi = dataset.GetResult('PTKLungROI', PTKContext.LungROI);
            left_and_right_lung_mask = dataset.GetResult('PTKROIDividedIntoLeftAndRight', PTKContext.LungROI);
            results = PTKGetLungROIFromLeftAndRightLungs(left_and_right_lung_mask, context, reporting);
        end
    end  
end