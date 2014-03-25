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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Lobes'
        ToolTip = 'Segment the pulmonary lobes'
        Category = 'Lobes'
        
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
                results = dataset.GetResult('PTKLobeMapForGasMRI');
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                results = dataset.GetResult('PTKLobeMapForMRI');
            else
                results = dataset.GetResult('PTKLobesFromFissurePlane');
            end
        end
    end
end