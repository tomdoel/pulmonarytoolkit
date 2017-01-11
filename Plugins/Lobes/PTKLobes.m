classdef PTKLobes < PTKPlugin
    % PTKLobes. Plugin to segment the pulmonary lobes.
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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Lobes'
        ToolTip = 'Segment the pulmonary lobes'
        Category = 'Lobes'
        
        AllowResultsToBeCached = true
        SuggestManualEditOnFailure = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        
        EnableModes = MimModes.EditMode
        SubMode = MimSubModes.FixedBoundariesEditing
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            if dataset.IsGasMRI
                results = dataset.GetResult('PTKLobeMapForGasMRI');
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                results = dataset.GetResult('PTKLobeMapForMRI'); % ToDo: not yet implemented for MRI
            else
                results = dataset.GetResult('PTKLobesFromFissurePlane');
            end
        end
        
        function result = GenerateDefaultEditedResultFollowingFailure(dataset, context, reporting)
            % Our initial edited result is based on the lungs, with lobe
            % details added in if they exist
            try
                result = dataset.GetResult('PTKLeftAndRightLungs');
                result_raw = result.RawImage;
                result_raw(result_raw == 2) = 5;
            catch 
                result = [];
                return;
            end
            
            try
                result_initial_lobes = dataset.GetResult('PTKLobesByVesselnessDensityUsingWatershed');
                result_initial_lobes_raw = result_initial_lobes.RawImage;
                result_raw(result_initial_lobes_raw > 0) = result_initial_lobes_raw(result_initial_lobes_raw > 0);
            catch
            end
            
            result.ChangeRawImage(result_raw);
        end        
    end
end