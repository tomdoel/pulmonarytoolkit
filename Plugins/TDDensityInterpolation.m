classdef TDDensityInterpolation < TDPlugin
    % TDDensityInterpolation. Plugin for interpolating density values to a
    % different voxel size
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
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
        ButtonText = 'Density Interpolation'
        ToolTip = 'Recomputes image density with different sized voxels'
        Category = 'Analysis'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(application, reporting)
            

            % The size of the 'voxels' for calculating the density.
            % Note if you want to change this, you should change the above 
            % property 
            %     AlwaysRunPlugin = false
            % so that the plug is forced to re-run
            
            interp_voxel_size_mm = [5, 5, 5];

            
            
            % Fetch the intensity of just the lung regions
            roi = application.GetResult('TDLungROI');
            left_and_right_lungs = application.GetResult('TDLeftAndRightLungs');
            
            reporting.ShowProgress('Finding lung region for density');
            mask = left_and_right_lungs.RawImage > 0;
            roi_lung = int16(roi.RawImage).*int16(mask);

            interp_voxel_size_units = interp_voxel_size_mm./roi.VoxelSize;
            image_size = roi.ImageSize;
            i_span = 1 : interp_voxel_size_units(1) : image_size(1);
            j_span = 1 : interp_voxel_size_units(2) : image_size(2);
            k_span = 1 : interp_voxel_size_units(3) : image_size(3);
            [interp_i, interp_j, interp_k] = ndgrid(i_span, j_span, k_span);
            
            % Interpolate dentisty values
            reporting.ShowProgress('Interpolating to new voxel grid');
            roi_interp = interpn(single(roi_lung), interp_i, interp_j, interp_k, '*linear');
            
            % Interpolate mask (gives a measure of how much of each voxel is
            % within the lung vs outside the lung)
            reporting.ShowProgress('Interpolating to new voxel size');
            roi_mask = interpn(single(mask), interp_i, interp_j, interp_k, '*linear');
            
            % Rescale voxels that are partially outside the lung, and remove
            % those more than 50% outside of the lung
            roi_interp = roi_interp./roi_mask;
            roi_interp(roi_mask < 0.5) = 0;
            
            roi_interp = roi_interp/max(roi_interp(:));
                        
            reporting.ShowProgress('Finding coordinates on original grid');            
            i_span_r = single(1 + (1:image_size(1))/interp_voxel_size_units(1));
            j_span_r = single(1 + (1:image_size(2))/interp_voxel_size_units(2));
            k_span_r = single(1 + (1:image_size(3))/interp_voxel_size_units(3));
            
            [interp_i, interp_j, interp_k] = ndgrid(i_span_r, j_span_r, k_span_r);
            interp_i = min(size(roi_interp, 1), round(interp_i));
            interp_j = min(size(roi_interp, 2), round(interp_j));
            interp_k = min(size(roi_interp, 3), round(interp_k));

            reporting.ShowProgress('Interpolation to original grid');
            indices = sub2ind(size(roi_interp), (interp_i(:)), (interp_j(:)), (interp_k(:)));
            results_raw = zeros(image_size, 'single');
            results_raw(:) = roi_interp(indices);

            results = roi.BlankCopy;
            
            
            results.ChangeRawImage(single(results_raw));
            results.ImageType = TDImageType.Scaled;

        end
    end
end