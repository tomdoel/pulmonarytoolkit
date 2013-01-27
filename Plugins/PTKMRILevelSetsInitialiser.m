classdef PTKMRILevelSetsInitialiser < PTKPlugin
    % PTKMRILevelSetsInitialiser. Plugin for producing an initialisation for
    % segmenting the lungs from MRI data
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    
    properties
        ButtonText = 'Initialise MRI <BR>Level Sets'
        ToolTip = 'Segment lungs from MRI images using level sets'
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
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            is_gas = dataset.IsGasMRI;

            left_and_right_lungs = dataset.GetResult('PTKLeftAndRightLungsInitialiser');
            roi = dataset.GetResult('PTKLungROI');
            left_roi = PTKGetLeftLungROIFromLeftAndRightLungs(roi, left_and_right_lungs, reporting);
            right_roi = PTKGetRightLungROIFromLeftAndRightLungs(roi, left_and_right_lungs, reporting);
            results = dataset.GetTemplateImage(PTKContext.LungROI);
            results_left = PTKMRILevelSetsInitialiser.ProcessLevelSets(left_roi, left_and_right_lungs, 2, is_gas, reporting);
            results_right = PTKMRILevelSetsInitialiser.ProcessLevelSets(right_roi, left_and_right_lungs, 1, is_gas, reporting);
            results_right.ResizeToMatch(results);
            results_left.ResizeToMatch(results);
            results_raw = uint8(results_right.RawImage);
            results_raw(results_left.RawImage) = 2;
            results.ChangeRawImage(results_raw);
            results.ImageType = PTKImageType.Colormap;
        end
        
        function results = ProcessLevelSets(lung_roi, left_and_right_lungs, mask_colour, is_gas, reporting)
            lung_mask = left_and_right_lungs.Copy;
            lung_mask.ResizeToMatch(lung_roi);
            lung_mask.ChangeRawImage(lung_mask.RawImage == mask_colour);

            if is_gas
                is_right = [];
            else
                is_right = mask_colour == 1;
            end
            results = PTKFillCoronalHoles(lung_mask, is_right, reporting);

            results.ImageType = PTKImageType.Colormap;
        end
    end
end