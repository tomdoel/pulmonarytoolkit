classdef PTKLeftAndRightLungs < PTKPlugin
    % PTKLeftAndRightLungs. Plugin to segment and label the left and right lungs.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKLeftAndRightLungs runs the library function
    %     PTKGetMainRegionExcludingBorder on the lung image thresholded using the
    %     plugin PTKThresholdLungFiltered, in order to generate a segmented lung
    %     image which includes the airways. The main airways are then obtained
    %     using the plugin PTKAirways and dilated before being removed. The
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
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        
        EnableModes = PTKModes.EditMode
        SubMode = PTKSubModes.EditBoundariesEditing
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            if dataset.IsGasMRI
                results = dataset.GetResult('PTKLungMapForGasMRI');
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                results = dataset.GetResult('PTKMRILevelSets');
            else
                results = dataset.GetResult('PTKLeftAndRightLungsInitialiser');
            end
        end
    end
end