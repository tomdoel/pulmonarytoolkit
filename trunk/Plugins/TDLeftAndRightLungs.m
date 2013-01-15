classdef TDLeftAndRightLungs < TDPlugin
    % TDLeftAndRightLungs. Plugin to segment and label the left and right lungs.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDLeftAndRightLungs runs the library function
    %     TDGetMainRegionExcludingBorder on the lung image thresholded using the
    %     plugin TDThresholdLungFiltered, in order to generate a segmented lung
    %     image which includes the airways. The main airways are then obtained
    %     using the plugin TDAirways and dilated before being removed. The
    %     resulting image contains just the lungs.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Left and <br>Right Lungs'
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
            if dataset.IsGasMRI
                results = dataset.GetResult('TDLungMapForGasMRI');
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                results = dataset.GetResult('TDMRILevelSets');
            else
                results = dataset.GetResult('TDLeftAndRightLungsInitialiser');
            end
        end
    end
end