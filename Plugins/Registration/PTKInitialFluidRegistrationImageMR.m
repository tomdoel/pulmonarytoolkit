classdef PTKInitialFluidRegistrationImageMR < PTKPlugin
    % PTKInitialFluidRegistrationImageMR.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
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
        ButtonText = 'Initial fluid <Br>registration left '
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
            mr_single_lung_mask = dataset.GetResult('PTKLungMaskForRegistration', context, '');
            
            if context == PTKContext.LeftLung
                gas_single_lung = dataset.GetResult('PTKGetLeftLungROI', [], '');
            elseif context == PTKContext.RightLung
                gas_single_lung = dataset.GetResult('PTKGetRightLungROI', [], '');
            end            
            mr_to_gas_affine_matrix = dataset.GetResult('PTKMRIToGasMRIMatrix');
            mr_to_gas_affine_matrix = mr_to_gas_affine_matrix.MrGasMrMatrix;
            
            % Find a voxel size to use for the registration image. We divide up thick
            % slices to give an approximately isotropic voxel size
            register_voxel_size = gas_single_lung.VoxelSize;
            register_voxel_size = register_voxel_size./round(register_voxel_size/min(register_voxel_size));
            
            % Adjust the thick slice proton MRI mask to include missing data
            mr_single_lung_mask = PTKAddMissingCoronalEdgeSlices(mr_single_lung_mask, register_voxel_size);
            
            % Resample the gas image to give us a template for the MR image
            gas_single_lung.Resample(register_voxel_size, '*nearest');
            gas_single_lung.AddBorder(20);

            % Zero translation, because the MR-gas MR translation has already been incorporated in the MR lung
            % mask from PTKLungMaskForRegistration
            affine_matrix = MimImageCoordinateUtilities.CreateAffineTranslationMatrix([0 0 0]);
            
            mr_single_lung_mask.ChangeRawImage(single(mr_single_lung_mask.RawImage));
            resampled_mr_mask = PTKRegisterImageAffine(mr_single_lung_mask, gas_single_lung, affine_matrix, '*linear', reporting);

            % For thick slices, we need to smooth
            resampled_mr_mask = MimGaussianFilter(resampled_mr_mask, 7.5);            
            resampled_mr_mask.ChangeRawImage(uint8(resampled_mr_mask.RawImage > 0.5));
            
            results = [];
            results.ResampledMrMask = resampled_mr_mask;
            results.MrGasMrMatrix = mr_to_gas_affine_matrix;
        end 
    end    
end

