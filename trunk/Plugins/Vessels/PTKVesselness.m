classdef PTKVesselness < PTKPlugin
    % PTKVesselness. Plugin for detecting blood vessels
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKVesselness computes a mutiscale vesselness filter based on Frangi et
    %     al., 1998. "Multiscale Vessel Enhancement Filtering". The filter
    %     returns a value at each point which in some sense representes the
    %     probability of that point belonging to a blood vessel.
    %
    %     To reduce memory usage, the left and right lungs are filtered
    %     separately and each is further divided into subimages using the
    %     PTKImageDividerHessian function. This will compute the eigenvalues of
    %     the Hessian matrix for each subimage and use these to compute the
    %     vesselness using the PTKComputeVesselnessFromHessianeigenvalues
    %     function.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Vesselness'
        ToolTip = 'Shows the multiscale vesselness filter for detecting blood vessels'
        Category = 'Vessels'
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Visibility = 'Developer'
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, reporting)
            
            right_lung = dataset.GetResult('PTKGetRightLungROI');
            
            reporting.PushProgress;
            
            reporting.UpdateProgressStage(0, 2);
            vesselness_right = PTKVesselness.ComputeVesselness(right_lung, reporting, false);
            
            reporting.UpdateProgressStage(1, 2);
            left_lung = dataset.GetResult('PTKGetLeftLungROI');
            vesselness_left = PTKVesselness.ComputeVesselness(left_lung, reporting, true);

            reporting.PopProgress;
            
            left_and_right_lungs = dataset.GetResult('PTKLeftAndRightLungs');
            
            results = PTKCombineLeftAndRightImages(dataset.GetTemplateImage(PTKContext.LungROI), vesselness_left, vesselness_right, left_and_right_lungs);
            
            lung = dataset.GetResult('PTKLeftAndRightLungs');
            results.ChangeRawImage(results.RawImage.*single(lung.RawImage > 0));
            results.ImageType = PTKImageType.Scaled;
        end
        
        function results = GenerateImageFromResults(results, ~, ~)
            vesselness_raw = 3*uint8(results.RawImage > 5);
            results.ChangeRawImage(vesselness_raw);
            results.ImageType = PTKImageType.Colormap;
        end        
        
    end
    
    methods (Static, Access = private)
        
        function vesselness = ComputeVesselness(image_data, reporting, is_left_lung)
            
            reporting.PushProgress;
            
            sigma_range = 0.5 : 0.5: 2;
            num_calculations = numel(sigma_range);
            vesselness = [];
            progress_index = 0;
            for sigma = sigma_range
                reporting.UpdateProgressStage(progress_index, num_calculations);
                progress_index = progress_index + 1;
                
                mask = [];
                vesselness_next = PTKImageDividerHessian(image_data.Copy, @PTKVesselness.ComputeVesselnessPartImage, mask, sigma, [], false, false, is_left_lung, reporting);
                vesselness_next.ChangeRawImage(100*vesselness_next.RawImage);
                if isempty(vesselness)
                    vesselness =  vesselness_next.Copy;
                else
                    vesselness.ChangeRawImage(max(vesselness.RawImage, vesselness_next.RawImage));
                end
            end
            
            reporting.PopProgress;
            
        end
                
        function vesselness_wrapper = ComputeVesselnessPartImage(hessian_eigs_wrapper, voxel_size)
            vesselness_wrapper = PTKComputeVesselnessFromHessianeigenvalues(hessian_eigs_wrapper, voxel_size);
        end
        
    end
end

