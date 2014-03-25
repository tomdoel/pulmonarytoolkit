classdef PTKLobeMapForGasMRI < PTKPlugin
    % PTKLobeMapForGasMRI.
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
        ButtonText = 'Gas MRI<Br>lobe map'
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
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, reporting)
            lobes_ct_right = dataset.GetResult('PTKLobes', [], 'CT');
            lobes_ct_left = lobes_ct_right.Copy;
            
            gas_image_template = dataset.GetTemplateImage(PTKContext.OriginalImage);
            
            % Right lung
            fluid_deformation_field_right = dataset.GetResult('PTKDeformationFieldCTToGasMRI', PTKContext.RightLung);

            lung_ct_right = dataset.GetResult('PTKLungMaskForRegistration', PTKContext.RightLung, 'CT');
            lobes_ct_right.ResizeToMatch(lung_ct_right);
            lobes_ct_right.ChangeRawImage(uint8(uint8(lobes_ct_right.RawImage).*uint8(lung_ct_right.RawImage > 0)));
            
            
            deformed_ct_lobes_right = PTKRegisterImageFluid(lobes_ct_right, fluid_deformation_field_right, '*nearest', reporting);
            deformed_ct_lobes_right = PTKRegisterImageZeroDeformationFluid(deformed_ct_lobes_right, gas_image_template, '*nearest', reporting);
            

            % Left lung
            fluid_deformation_field_left = dataset.GetResult('PTKDeformationFieldCTToGasMRI', PTKContext.LeftLung);

            lung_ct_left = dataset.GetResult('PTKLungMaskForRegistration', PTKContext.LeftLung, 'CT');
            lobes_ct_left.ResizeToMatch(lung_ct_left);
            lobes_ct_left.ChangeRawImage(uint8(uint8(lobes_ct_left.RawImage).*uint8(lung_ct_left.RawImage > 0)));
            
            deformed_ct_lobes_left = PTKRegisterImageFluid(lobes_ct_left, fluid_deformation_field_left, '*nearest', reporting);
            deformed_ct_lobes_left = PTKRegisterImageZeroDeformationFluid(deformed_ct_lobes_left, gas_image_template, '*nearest', reporting);
            
            results = dataset.GetTemplateImage(PTKContext.OriginalImage);
            results.ChangeRawImage(zeros(results.ImageSize, 'uint8'));
            
            right_lung_mask = deformed_ct_lobes_right.Copy;
            right_lung_mask.ChangeRawImage((right_lung_mask.RawImage == 1) | (right_lung_mask.RawImage == 2) | (right_lung_mask.RawImage == 4));
            results.ChangeSubImageWithMask(deformed_ct_lobes_right, right_lung_mask);

            left_lung_mask = deformed_ct_lobes_left.Copy;
            left_lung_mask.ChangeRawImage((left_lung_mask.RawImage == 5) | (left_lung_mask.RawImage == 6));
            results.ChangeSubImageWithMask(deformed_ct_lobes_left, left_lung_mask);
            
            results.ImageType = PTKImageType.Colormap;
        end 
    end    
end

