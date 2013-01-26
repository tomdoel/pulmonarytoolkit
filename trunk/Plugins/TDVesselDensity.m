classdef TDVesselDensity < TDPlugin
    % TDVesselDensity. Plugin for approximating a measure of vesesl density
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDVesselDensity computes a measure which gives an approximation for
    %     the density of blood vesels in the region surrounding each voxel. This
    %     is computed by applying a strong Gaussian filter to the multiscale
    %     vesselness filter calculated using the TDVesselness plugin.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Vessel Density'
        ToolTip = 'Approximates a vessel density by Gaussian filtering the multiscale vesselness filter'
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
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, ~)    
            lung_mask = dataset.GetResult('TDLeftAndRightLungs');
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage > 0));
            vesselness = dataset.GetResult('TDVesselness');
            results = vesselness.BlankCopy;
                        
            filtered_vesselness = TDVesselDensity.CalculateVesselDensity(vesselness);
            
            filtered_vesselness_raw = filtered_vesselness.RawImage;
            filtered_vesselness_raw(~(lung_mask.RawImage > 0)) = 0;
            results.ChangeRawImage(filtered_vesselness_raw);
            results.ImageType = TDImageType.Scaled;
        end
        
    end
    
    methods (Static, Access = private)
        function filtered_vesselness = CalculateVesselDensity(vesselness)
            vesselness_raw = single(vesselness.RawImage);
            filter_size = 10;            
            vesselness.ChangeRawImage(vesselness_raw);
            filtered_vesselness = TDGaussianFilter(vesselness, filter_size);
        end
    end
end