classdef TDLeftAndRightLungsInitialiser < TDPlugin
    % TDLeftAndRightLungsInitialiser. Plugin to segment and label the left and right lungs.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Initial Left and <br>Right Lungs'
        ToolTip = 'Separate and label left and right lungs'
        Category = 'Lungs'
        
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            reporting.ShowProgress('Separating lungs');
            
            if strcmp(dataset.GetImageInfo.Modality, 'MR')
                unclosed_lungs = dataset.GetResult('TDUnclosedLungIncludingTrachea', TDContext.LungROI);
            else
                unclosed_lungs = dataset.GetResult('TDUnclosedLungExcludingTrachea', TDContext.LungROI);
            end
            
            lung_roi = dataset.GetResult('TDLungROI');
            
            filtered_threshold_lung = dataset.GetResult('TDThresholdLungFiltered', TDContext.LungROI);
            
            results = TDGetLeftAndRightLungs(unclosed_lungs, filtered_threshold_lung, lung_roi, reporting);
        end
    end
end