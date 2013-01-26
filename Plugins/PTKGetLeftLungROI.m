classdef TDGetLeftLungROI < TDPlugin
    % TDGetLeftLungROI. Plugin for finding the left lung region of interest.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDGetLeftLungROI runs the library function TDLeftAndRightLungs to 
    %     segment the left and right lungs, and uses this to determine a region 
    %     of interest for the left lung only.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Left Lung <BR>ROI'
        ToolTip = 'Change the context to display the left lung'
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
            roi = dataset.GetResult('TDLungROI');
            left_and_right_lung_mask = dataset.GetResult('TDLeftAndRightLungs');
            results = TDGetLeftLungROIFromLeftAndRightLungs(roi, left_and_right_lung_mask, reporting);
        end
    end
end