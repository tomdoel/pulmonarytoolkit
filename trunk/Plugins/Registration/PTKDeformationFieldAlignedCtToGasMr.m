classdef PTKDeformationFieldAlignedCtToGasMr < PTKPlugin
    % PTKDeformationFieldAlignedCtToGasMr.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKDeformationFieldAlignedCtToGasMr solves the fluid registration
    %     between a CT left lung mask (which has already been rigidly
    %     registered) to proton MRI images
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Fluid CT-MR <Br>registration'
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
            
            mr_initial = dataset.GetResult('PTKDownsampledInitialFluidRegistrationImageMR', context, '');
            ct_initial = dataset.GetResult('PTKDownsampledInitialFluidRegistrationImageCT', context, '');
            
            deformation_field_single_lung = PTKSolveMatchedImagesForFluidRegistration(ct_initial.ResampledCtMask, mr_initial.ResampledMrMask, reporting);

            results = deformation_field_single_lung;
            
            
            
            % For verification
            ct_verify = ct_initial.ResampledCtMask.Copy;
            ct_verify.ChangeRawImage(single(ct_verify.RawImage));
            resampled_ct_mask = PTKRegisterImageFluid(ct_verify, deformation_field_single_lung, '*linear', reporting);
            resampled_ct_mask.ChangeRawImage(uint8(resampled_ct_mask.RawImage > 0.5));
            PTKVisualiseImageFusion(mr_initial.ResampledMrMask, resampled_ct_mask);
        end 
    end    
end

