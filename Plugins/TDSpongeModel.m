classdef TDSpongeModel < TDPlugin
    % TDSpongeModel. Plugin for illustrating slice-by-slice relation between
    % gravitational compartments and volumes of air and tissue.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDSpongeModel produces an illustration of the air and tissue volumes
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
            roi = application.GetResult('TDLungROI');
                        
            results = roi.Copy;
            results.Clear;
            
            if ~roi.IsCT
                reporting.ShowMessage('TDSpongeModel:NotCTImage', 'Cannot perform density analysis as this is not a CT image');
                return;
            end
            
            
            left_and_right_lungs = application.GetResult('TDLeftAndRightLungs');
            number_axial_slices = roi.ImageSize(3);

            ct_air = -1000;
            ct_water = 0;
            
            reporting.UpdateProgressAndMessage(0, 'Calculating gas volume per slice');
            
            for axial_slice_number = 1 : number_axial_slices
                reporting.UpdateProgressValue(100*(axial_slice_number - 1)/number_axial_slices);
                axial_slice = roi.GetSlice(axial_slice_number, TDImageOrientation.Axial);
                axial_slice_mask = left_and_right_lungs.GetSlice(axial_slice_number, TDImageOrientation.Axial);
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
                            
                            density_values = gravity_slice(gravity_slice_mask(:));
                            hu_values = roi.GreyscaleToHounsfield(density_values);
                            mean_ct_value = mean(hu_values);
                            fraction_air = mean_ct_value/(ct_air - ct_water);
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
                    results.ReplaceImageSlice(output_slice, axial_slice_number, TDImageOrientation.Axial);
                end
                
                
            end
            
            surface = application.GetResult('TDLungSurface');
            results_raw = uint8(results.RawImage);
            results_raw(surface.RawImage > 0) = 7;
            results.ChangeRawImage(results_raw);
            results.ImageType = TDImageType.Colormap;
            


        end
    end
end