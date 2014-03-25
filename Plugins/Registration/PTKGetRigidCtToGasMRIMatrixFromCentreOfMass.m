classdef PTKGetRigidCtToGasMRIMatrixFromCentreOfMass < PTKPlugin
    % PTKGetRigidCtToGasMRIMatrixFromCentreOfMass.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKGetRigidCtToGasMRIMatrixFromCentreOfMass performs a rigid registration
    %     of the CT dataset based on the centroids of the lung masks
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Initial fluid CT <Br>registration COM'
        ToolTip = ''
        Category = 'Registration'
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, reporting)
            ct_left_lung_mask = dataset.GetResult('PTKLungMaskForRegistration', PTKContext.LeftLung, 'CT');
            mr_initial_left = dataset.GetResult('PTKInitialFluidRegistrationImageMR', PTKContext.LeftLung, '');
            [com_affine_matrix_left, ~] = PTKRegisterCentroid(ct_left_lung_mask, mr_initial_left.ResampledMrMask, reporting);
                        
            ct_right_lung_mask = dataset.GetResult('PTKLungMaskForRegistration', PTKContext.RightLung, 'CT');
            mr_initial_right = dataset.GetResult('PTKInitialFluidRegistrationImageMR', PTKContext.RightLung, '');
            [com_affine_matrix_right, ~] = PTKRegisterCentroid(ct_right_lung_mask, mr_initial_right.ResampledMrMask, reporting);

            com_affine_matrix = (com_affine_matrix_left + com_affine_matrix_right)/2;

            results = com_affine_matrix;            
        end 
    end    
end

