classdef TDDensityAverage < TDPlugin
    % TDDensityAverage. Plugin for finding density averaged over a neighbourhood
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDDensityAverage computes the density of each voxel, averaged over a
    %     3x3x3 neighbourhood.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Average Density'
        ToolTip = 'Compute the lung density averaged over a 3x3x3 neighbourhood'
        Category = 'Lungs'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            reporting.ShowProgress('Fetching ROI');
            lung_roi = dataset.GetResult('TDLungROI');
            
            density_average_el = ones(5,5,5);
            size_el = numel(density_average_el);
            
            % Create a lung mask excluding the surface layer of voxels
            reporting.ShowProgress('Computing lung mask');
            mask = dataset.GetResult('TDLeftAndRightLungs');
            surface = dataset.GetResult('TDLungSurface');
            surface = convn(logical(surface.RawImage), true(3,3,3), 'same');
            mask.ChangeRawImage((mask.RawImage > 0) & (~surface));
            
            % Remove the mask from the lung image
            lung_roi.ChangeRawImage(int16(lung_roi.RawImage).*int16(mask.RawImage));

            % Average the mask, in order to produce a scaling for the density to
            % take into account edge voxels
            reporting.ShowProgress('Computing scaling factor');
            mask_averaged = convn(single(mask.RawImage), density_average_el, 'same');
            zero_mask = mask_averaged == 0;
            mask_averaged(zero_mask) = size_el;
            
            reporting.ShowProgress('Computing average lung density');
            density_g_mL_image = TDConvertCTToDensity(lung_roi);
            density_averaged = convn(density_g_mL_image.RawImage, density_average_el, 'same')/size_el;
            
            % Rescale image. This adjusts for lower densities near the
            % lung boundaries where the contributing density values have been
            % masked out
            reporting.ShowProgress('Rescaling lung density');
            density_averaged = density_averaged.*(size_el/mask_averaged);
            density_averaged(zero_mask) = 0;
            
            reporting.ShowProgress('Storing results');
            results = lung_roi.BlankCopy;
            results.ChangeRawImage(density_averaged);
            results.ImageType = TDImageType.Scaled;
        end
    end
end