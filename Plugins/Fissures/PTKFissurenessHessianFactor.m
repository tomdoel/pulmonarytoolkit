classdef PTKFissurenessHessianFactor < PTKPlugin
    % PTKFissureApproximation. Plugin to detect fissures using analysis of the
    %     Hessian matrix
    %
    % This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    % the gui, or through the interfaces provided by the Pulmonary Toolkit.
    % See PTKPlugin.m for more information on how to run plugins.
    %
    % Plugins should not be run directly from your code.
    %
    %     This is an intermediate stage towards lobar segmentation.
    %
    %     PTKFissurenessHessianFactor computes the components of the fissureness
    %     generated using analysis of eigenvalues of the Hessian matrix.
    %
    %     For more information, see 
    %     [Doel et al., Pulmonary lobe segmentation from CT images using
    %     fissureness, airways, vessels and multilevel B-splines, 2012]
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Fissureness <BR>(Hessian part)'
        ToolTip = 'The part of the fissureness filter which uses Hessian-based analysis'
        Category = 'Fissures'

        AllowResultsToBeCached = false
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Visibility = 'Developer'
        Version = 2
        
        MemoryCachePolicy = 'Temporary'
        DiskCachePolicy = 'Off'        
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            reporting.UpdateProgressValue(0);
            left_and_right_lungs = dataset.GetResult('PTKLeftAndRightLungs');
            
            right_lung = dataset.GetResult('PTKGetRightLungROI');
            
            fissureness_right = PTKFissurenessHessianFactor.ComputeFissureness(right_lung, left_and_right_lungs, reporting, false);
            
            reporting.UpdateProgressValue(50);
            left_lung = dataset.GetResult('PTKGetLeftLungROI');
            fissureness_left = PTKFissurenessHessianFactor.ComputeFissureness(left_lung, left_and_right_lungs, reporting, true);
            
            reporting.UpdateProgressValue(100);
            results = PTKCombineLeftAndRightImages(dataset.GetTemplateImage(PTKContext.LungROI), fissureness_left, fissureness_right, left_and_right_lungs);
            
            results.ImageType = PTKImageType.Scaled;
        end        
    end
    
    methods (Static, Access = private)
        
        function lung = DuplicateImageInMask(lung, mask_raw)
            mask_raw = mask_raw > 0;
            if any(mask_raw(:) > 0)
                [~, labelmatrix] = bwdist(mask_raw);
                lung(~mask_raw(:)) = lung(labelmatrix(~mask_raw(:)));
            else
                lung(:) = 0;
            end
        end
        
        function fissureness = ComputeFissureness(image_data, left_and_right_lungs, reporting, is_left_lung)
            
            left_and_right_lungs = left_and_right_lungs.Copy;
            left_and_right_lungs.ResizeToMatch(image_data);
            image_data.ChangeRawImage(PTKFissurenessHessianFactor.DuplicateImageInMask(image_data.RawImage, left_and_right_lungs.RawImage));
            
            mask = [];
            fissureness = PTKImageDividerHessian(image_data, @PTKFissurenessHessianFactor.ComputeFissurenessPartImage, mask, 1.5, [], false, false, is_left_lung, reporting);
        end
        
        function fissureness_wrapper = ComputeFissurenessPartImage(hessian_eigs_wrapper, voxel_size)
            fissureness_wrapper = PTKComputeFissurenessFromHessianeigenvalues(hessian_eigs_wrapper, voxel_size);
        end
    end
end