classdef PTKGetRightLungROI < PTKPlugin
    % PTKGetRightLungROI. Plugin for finding the right lung region of interest.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKGetRightLungROI runs the library function PTKLeftAndRightLungs to 
    %     segment the left and right lungs, and uses this to determine a region 
    %     of interest for the right lung only.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Right Lung<BR>ROI'
        ToolTip = 'Change the context to display the right lung'
        Category = 'Context'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceImage'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            roi = dataset.GetResult('PTKLungROI');
            left_and_right_lung_mask = dataset.GetResult('PTKLeftAndRightLungs');
            results = PTKGetRightLungROIFromLeftAndRightLungs(roi, left_and_right_lung_mask, reporting);
        end
    end  
end