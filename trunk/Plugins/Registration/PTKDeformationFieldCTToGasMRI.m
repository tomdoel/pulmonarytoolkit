classdef PTKDeformationFieldCTToGasMRI < PTKPlugin
    % PTKDeformationFieldCTToGasMRI.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKDeformationFieldCTToGasMRI solves the fluid registration problem
    %     between a CT left lung image and a gas MRI image, by solving the
    %     registation between CT and MRI and then applying a rigid transform
    %     between MRI and gas MRI,
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Fluid CT <Br>registration'
        ToolTip = ''
        Category = 'Registration'
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
        Context = PTKContextSet.SingleLung
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, context, reporting)
            ct_to_mr_affine_matrix_single_lung = dataset.GetResult('PTKGetRigidCtToGasMRIMatrixFromCentreOfMass', context);
            deformation_field_single_lung = dataset.GetResult('PTKDeformationFieldAlignedCtToGasMr', context, '');
            deformation_field_single_lung = PTKImageCoordinateUtilities.AdjustDeformationFieldForInitialAffineTransformation(deformation_field_single_lung, ct_to_mr_affine_matrix_single_lung);
            results = deformation_field_single_lung;
        end 
    end    
end

