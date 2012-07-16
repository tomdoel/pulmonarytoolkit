classdef TDLeftAndRightLungs < TDPlugin
    % TDLeftAndRightLungs. Plugin to segment and label the left and right lungs.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDLeftAndRightLungs runs the library function
    %     TDGetMainRegionExcludingBorder on the lung image thresholded using the
    %     plugin TDThresholdLungFiltered, in order to generate a segmented lung
    %     image which includes the airways. The main airways are then obtained
    %     using the plugin TDAirways and dilated before being removed. The
    %     resulting image contains just the lungs.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Left and <br>Right Lungs'
        ToolTip = 'Separate and label left and right lungs'
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
            reporting.ShowProgress('Separating lungs');
            results = TDLeftAndRightLungs.SeparateAndLabelLungs(dataset, reporting);
            
            reporting.UpdateProgressAndMessage(25, 'Closing right lung');
            right_lung = results.Copy;
            right_lung.ChangeRawImage(right_lung.RawImage == 1);
            right_lung.CropToFit;
            
            % Perform morphological closing with a spherical structure element of radius 8mm
            right_lung.MorphWithBorder(@imclose, 8);
            % Fill any remaining holes inside the 3D image
            right_lung = TDFillHolesInImage(right_lung);
            
            right_lung.ChangeRawImage(uint8(right_lung.RawImage));
            
            reporting.UpdateProgressAndMessage(50, 'Closing left lung');
            left_lung = results.Copy;
            left_lung.ChangeRawImage(left_lung.RawImage == 2);
            left_lung.CropToFit;

            % Perform morphological closing with a spherical structure element of radius 8mm
            left_lung.MorphWithBorder(@imclose, 8);
            % Fill any remaining holes inside the 3D image
            left_lung = TDFillHolesInImage(left_lung);

            left_lung.ChangeRawImage(2*uint8(left_lung.RawImage));
            
            reporting.UpdateProgressAndMessage(75, 'Combining');
            
            results.Clear;
            results.ChangeSubImage(left_lung);
            results2 = results.Copy;
            results2.Clear;
            results2.ChangeSubImage(right_lung);
            results.ChangeRawImage(min(2, results.RawImage + results2.RawImage));
            results.ImageType = TDImageType.Colormap;
        end
    end
    
    methods (Static, Access = private)
        
        function both_lungs = SeparateAndLabelLungs(dataset, reporting)
            unclosed_lungs = dataset.GetResult('TDUnclosedLungExcludingTrachea');
            both_lungs = unclosed_lungs.Copy;
            
            filtered_threshold = dataset.GetResult('TDThresholdLungFiltered');
            
            both_lungs.ChangeRawImage(uint8(both_lungs.RawImage & (filtered_threshold.RawImage == 1)));
            
            % Find the connected components in this mask
            CC = bwconncomp(both_lungs.RawImage > 0, 26);
            
            % Find largest regions
            num_pixels = cellfun(@numel, CC.PixelIdxList);
            total_num_pixels = sum(num_pixels);
            minimum_required_voxels_per_lung = total_num_pixels/10;
            [largest_area_numpixels, largest_areas_indices] = sort(num_pixels, 'descend');
            
            iter_number = 0;
            
            % If there is only one large connected component, the lungs are connected,
            % so we attempt to disconnect them using morphological operations
            while (length(largest_areas_indices) < 2) || (largest_area_numpixels(2) < minimum_required_voxels_per_lung)
                if (iter_number > 10)
                    reporting.Error('TDClosedLabeledLeftAndRightLungs:FailedToSeparateLungs', ['Failed to separate left and right lungs after ' num2str(iter_number) ' opening attempts']);
                end
                iter_number = iter_number + 1;
                reporting.ShowMessage('TDLeftAndRightLungs:OpeningLungs', ['Failed to separate left and right lungs. Retrying after morphological opening attempt ' num2str(iter_number) '.']);
                opening_size = iter_number;
                image_to_close = both_lungs.Copy;
                image_to_close.BinaryMorph(@imopen, opening_size);
                
                CC = bwconncomp(image_to_close.RawImage > 0, 26);
                
                % Find largest region
                num_pixels = cellfun(@numel, CC.PixelIdxList);
                total_num_pixels = sum(num_pixels);
                minimum_required_voxels_per_lung = total_num_pixels/10;
                
                [largest_area_numpixels, largest_areas_indices] = sort(num_pixels, 'descend');
                
            end
            
            reporting.ShowMessage('TDLeftAndRightLungs:LungsFound', 'Lung regions found.');
            
            largest_area_index = largest_areas_indices(1);
            second_largest_area_index = largest_areas_indices(2);
            
            region_1_voxels = CC.PixelIdxList{largest_area_index};
            region_1_centroid = TDLeftAndRightLungs.GetCentroid(both_lungs.ImageSize, region_1_voxels);
            
            region_2_voxels = CC.PixelIdxList{second_largest_area_index};
            region_2_centroid = TDLeftAndRightLungs.GetCentroid(both_lungs.ImageSize, region_2_voxels);
            
            both_lungs.Clear;
            both_lungs.ImageType = TDImageType.Colormap;
            if region_1_centroid(2) < region_2_centroid(2)
                region_1_colour = 1;
                region_2_colour = 2;
            else
                region_1_colour = 2;
                region_2_colour = 1;
            end
            
            % Watershed to fill remaining voxels
            roi = dataset.GetResult('TDLungROI');
            lung_exterior = unclosed_lungs.RawImage == 0;
            starting_voxels = zeros(both_lungs.ImageSize, 'int8');
            starting_voxels(region_1_voxels) = region_1_colour;
            starting_voxels(region_2_voxels) = region_2_colour;
            starting_voxels(lung_exterior) = -1;
                        
            labeled_output = TDWatershedFromStartingPoints(int16(roi.RawImage), starting_voxels);
            labeled_output(labeled_output == -1) = 0;
                        
            both_lungs.ChangeRawImage(uint8(labeled_output));
            both_lungs.ImageType = TDImageType.Colormap;            
        end
        
        function centroid = GetCentroid(image_size, new_coords_indices)
            [p_x, p_y, p_z] = TDImageCoordinateUtilities.FastInd2sub(image_size, new_coords_indices);
            centroid = [mean(p_x), mean(p_y), mean(p_z)];
        end
        
    end
end