classdef PTKLungMapForGasMRI < PTKPlugin
    % PTKLungMapForGasMRI.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     This plugin gets the proton MRI left and right lung mask and
    %     registers it to the gas MRI image
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Gas MRI<Br>lung map'
        ToolTip = ''
        Category = 'Lobes'
        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, reporting)
            lungs_mr = dataset.GetResult('PTKLeftAndRightLungs', [], 'MR');
            mr_to_gas_matrix = dataset.GetResult('PTKMRIToGasMRIMatrix');
            
            results = PTKRegisterImageAffine(lungs_mr, dataset.GetTemplateImage(PTKContext.OriginalImage), mr_to_gas_matrix.MrGasMrMatrix, '*nearest', reporting);
            results.ChangeRawImage(uint8(results.RawImage));
            results.ImageType = PTKImageType.Colormap;
        end 
    end    
end

