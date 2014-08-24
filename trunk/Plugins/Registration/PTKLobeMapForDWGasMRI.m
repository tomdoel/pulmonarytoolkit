classdef PTKLobeMapForDWGasMRI < PTKPlugin
    % PTKLobeMapForDWGasMRI.
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
        ButtonText = 'DW Gas MRI<Br>lobe map'
        ToolTip = ''
        Category = 'Lobes'
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
        Visibility = 'Developer'
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, reporting)
            lobes = dataset.GetResult('PTKLobes', [], 'CT');
            gas_image_template = dataset.GetTemplateImage(PTKContext.OriginalImage, 'XeDiff0');
            fluid_deformation_field_right = dataset.GetResult('PTKDeformationFieldCTToGasMRI', PTKContext.RightLung);
            fluid_deformation_field_left = dataset.GetResult('PTKDeformationFieldCTToGasMRI', PTKContext.LeftLung);
            lung_ct_right = dataset.GetResult('PTKLungMaskForRegistration', PTKContext.RightLung, 'CT');
            lung_ct_left = dataset.GetResult('PTKLungMaskForRegistration', PTKContext.LeftLung, 'CT');
            
            results = PTKMapLobesToImage(lobes, gas_image_template, fluid_deformation_field_right, lung_ct_right, fluid_deformation_field_left, lung_ct_left, reporting);
        end
    end
end

