classdef PTKDownsampledInitialFluidRegistrationImageCT < PTKPlugin
    % PTKDownsampledInitialFluidRegistrationImageCT.
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
        ButtonText = 'Initial fluid CT <Br>registration '
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
            ct_to_mr_affine_matrix = dataset.GetResult('PTKGetRigidCtToGasMRIMatrixFromCentreOfMass', PTKContext.LungROI);
            
            mr_initial_downsampled = dataset.GetResult('PTKDownsampledInitialFluidRegistrationImageMR', context, '');
            
            ct_single_lung_mask = dataset.GetResult('PTKLungMaskForRegistration', context, 'CT');

            ct_single_lung_mask.AddBorder(10);

            resampled_ct_mask_template = mr_initial_downsampled.ResampledMrMask.BlankCopy;
            resampled_ct_mask_template.AddBorder(10);
            
            ct_single_lung_mask.ChangeRawImage(single(ct_single_lung_mask.RawImage));
            resampled_ct_mask = PTKRegisterImageAffine(ct_single_lung_mask, resampled_ct_mask_template, ct_to_mr_affine_matrix, '*linear', reporting);
            resampled_ct_mask.ChangeRawImage(uint8(resampled_ct_mask.RawImage > 0.5));
            
            resampled_ct_mask.BinaryMorph(@imclose, 5);
            
            results = [];
            results.ResampledCtMask = resampled_ct_mask;
            results.CtMrMatrix = ct_to_mr_affine_matrix;            
        end 
    end    
end

