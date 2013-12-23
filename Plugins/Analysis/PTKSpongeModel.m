classdef PTKSpongeModel < PTKPlugin
    % PTKSpongeModel. Plugin for illustrating slice-by-slice relation between
    % gravitational compartments and volumes of air and tissue.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKSpongeModel produces an illustration of the air and tissue volumes
    %     in different gravitational compartments, on a slice by slice basis.
    %     Results should be viewed in the axial orientation. The results show a
    %     schematic illustration of the slice divided into 10 gravitational
    %     compartments, with each compartment filled with red (tissue) and blue
    %     (air) to represent the volumes of air and tissue in that compartment.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Gas vs. Tissue'
        ToolTip = 'Shows a schematic representation of a sponge model based on density analysis'
        Category = 'Analysis'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(application, reporting)
            roi = application.GetResult('PTKLungROI');
                        
            results = roi.Copy;
            results.Clear;
            
            if ~roi.IsCT
                reporting.ShowMessage('PTKSpongeModel:NotCTImage', 'Cannot perform density analysis as this is not a CT image');
                return;
            end
            
            
            left_and_right_lungs = application.GetResult('PTKLeftAndRightLungs');
            number_axial_slices = roi.ImageSize(3);

            reporting.UpdateProgressAndMessage(0, 'Calculating gas volume per slice');
            
            for axial_slice_number = 1 : number_axial_slices
                reporting.UpdateProgressValue(100*(axial_slice_number - 1)/number_axial_slices);
                axial_slice = roi.GetSlice(axial_slice_number, PTKImageOrientation.Axial);
                axial_slice_mask = left_and_right_lungs.GetSlice(axial_slice_number, PTKImageOrientation.Axial);
                [axial_i_coords, ~, ~] = find(axial_slice_mask > 0);
                if ~isempty(axial_i_coords)
                    min_i = min(axial_i_coords(:));
                    max_i = max(axial_i_coords(:));
                    gravity_slice_boundaries = round(linspace(min_i, max_i + 1, 11));
                    output_slice = zeros(size(axial_slice), 'uint8');
                    for gravity_slice_number = 1 : 10
                        reporting.UpdateProgressValue(100*(axial_slice_number - 1 + (gravity_slice_number - 1)/10)/number_axial_slices);
                        gravity_slice = axial_slice(gravity_slice_boundaries(gravity_slice_number) : gravity_slice_boundaries(gravity_slice_number + 1) - 1, :);
                        gravity_slice_lr = axial_slice_mask(gravity_slice_boundaries(gravity_slice_number) : gravity_slice_boundaries(gravity_slice_number + 1) - 1, :);
                        
                        output_gravity_slice = zeros(size(gravity_slice), 'uint8');
                        
                        for left_right = 1 : 2
                            
                            gravity_slice_mask = gravity_slice_lr == left_right;
                            mask_indices = find(gravity_slice_mask);

                            results_metrics = PTKSpongeModel.ComputeAirTissueFraction(gravity_slice, gravity_slice_mask, roi, reporting);
                            fraction_air = results_metrics.AirFractionPercent/100;
                            
                            [~, j_coordinates, ~] = ind2sub(size(gravity_slice_mask), mask_indices);
                            if ~isempty(j_coordinates)
                                if left_right == 1
                                    j_divide = prctile(j_coordinates, 100-100*fraction_air);
                                    output_gravity_slice(mask_indices(j_coordinates <= j_divide)) = 3;
                                    output_gravity_slice(mask_indices(j_coordinates > j_divide)) = 4;
                                else
                                    j_divide = prctile(j_coordinates, 100*fraction_air);
                                    output_gravity_slice(mask_indices(j_coordinates <= j_divide)) = 4;
                                    output_gravity_slice(mask_indices(j_coordinates > j_divide)) = 3;
                                end
                            end
                        end
                        output_slice(gravity_slice_boundaries(gravity_slice_number) : gravity_slice_boundaries(gravity_slice_number + 1) - 1, :) = output_gravity_slice;
                        output_slice(gravity_slice_boundaries(gravity_slice_number), :) = 7*(axial_slice_mask(gravity_slice_boundaries(gravity_slice_number), :) > 0);
                    end
                    results.ReplaceImageSlice(output_slice, axial_slice_number, PTKImageOrientation.Axial);
                end
                
                
            end
            
            surface = application.GetResult('PTKLungSurface');
            results_raw = uint8(results.RawImage);
            results_raw(surface.RawImage > 0) = 7;
            results.ChangeRawImage(results_raw);
            results.ImageType = PTKImageType.Colormap;
            


        end
        
        
        % We could use PTKComputeAirTissueFraction, but that requires PTKImage
        % as inputs
        function results = ComputeAirTissueFraction(roi, mask, template, reporting)
            ct_air_hu = -1000;
            ct_water_hu = 0;
            
            % Get the density values from the image
            raw_values = roi(mask(:));
            
            % Convert to HU
            hu_values = template.GreyscaleToHounsfield(raw_values);
            
            % Convert to g/ml
            density_gml = PTKConvertHuToDensity(raw_values);
            
            mean_density_gml = mean(density_gml);
            std_density_gml = std(density_gml);
            
            mean_density_hu = mean(double(hu_values));
            std_density_hu = std(double(hu_values));

            fraction_air = 100*mean_density_hu/(ct_air_hu - ct_water_hu);
            fraction_tissue = 100 - fraction_air;
            
            results = PTKMetrics;
            results.AddMetric('AirFractionPercent', fraction_air, '% of air');
            results.AddMetric('TissueFractionPercent', fraction_tissue, '% of tissue');
            results.AddMetric('MeanDensityGml', mean_density_gml, 'Mean density (g/ml)');
            results.AddMetric('StdDensityGml', std_density_gml, 'Std of density (g/ml)');
            results.AddMetric('MeanDensityHu', mean_density_hu, 'Mean density (HU)');
            results.AddMetric('StdDensityHu', std_density_hu, 'Std of density (HU)');
        end
        
    end
end