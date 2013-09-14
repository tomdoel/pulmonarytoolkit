classdef PTKDensityGridPerLobe < PTKPlugin
    % PTKDensityGridPerLobe. Plugin for finding density points in a grid within
    %     each lobe and saving to a file
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
        ButtonText = 'Density grid<br> per lobe'
        ToolTip = 'Compute the lung density averaged over a 3x3x3 neighbourhood'
        Category = 'Analysis'

        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            reporting.ShowProgress('Computing lobes and density');
            
            % Get the lobe mask
            lobes = dataset.GetResult('PTKLobesFromFissurePlane');            

            % Work out the interpolation grid spacing
            approx_number_grid_points = 30000;
            grid_spacing_mm = lobes.ComputeResamplingGridSpacing(approx_number_grid_points);
            grid_spacing_3 = [grid_spacing_mm, grid_spacing_mm, grid_spacing_mm];
            
            % Get the average density
            density_average_result = dataset.GetResult('PTKDensityAverage');
            density_average = density_average_result.DensityAverage;
            density_average_mask = density_average_result.DensityAverageMask;

            reporting.ShowProgress('Resample and saving density per lobe to files');

            lobe_names = {'RightUpper', 'RightMid', 'RightLower', 'LeftUpper', 'LeftLower'};
            lobe_colours = [1, 2, 4, 5, 6];
            for lobe_index = 1 : 5
                
                reporting.UpdateProgressValue(round(100*(lobe_index - 1)/5));
                
                % Select the lobe and crop the image
                lobes_copy = lobes.Copy;
                lobes_copy.ChangeRawImage(lobes_copy.RawImage == lobe_colours(lobe_index));
                lobes_copy.CropToFit;
                
                % Crop the density to the same size
                density_average_copy = density_average.Copy;
                density_average_copy.ResizeToMatch(lobes_copy);
                density_average_mask_copy = density_average_mask.Copy;
                density_average_mask_copy.ResizeToMatch(lobes_copy);

                % Resample lobes and density
                lobes_copy.Resample(grid_spacing_3, '*nearest')
                density_average_copy.Resample(grid_spacing_3, '*nearest')
                density_average_mask_copy.Resample(grid_spacing_3, '*nearest')
                
                local_indices_for_this_lobe = find(lobes_copy.RawImage & density_average_mask_copy.RawImage);
                global_indices_for_this_lobe = lobes_copy.LocalToGlobalIndices(local_indices_for_this_lobe);
                [ic, jc, kc] = lobes_copy.GlobalIndicesToCoordinatesMm(global_indices_for_this_lobe);
                density_values = density_average_copy.RawImage(local_indices_for_this_lobe);
                PTKDensityGridPerLobe.SaveToFile(dataset, lobe_names{lobe_index}, ic, jc, kc, density_values)
            end
            
            results = dataset.GetTemplateImage(PTKContext.LungROI);
        end
        
        function SaveToFile(dataset, lobe_name, ic, jc, kc, density_values)
            results_directory = dataset.GetOutputPathAndCreateIfNecessary;
            
            results_file_name = fullfile(results_directory, ['DensityValues_' lobe_name '.txt']);
            file_handle = fopen(results_file_name, 'w');
            
            number_points = length(ic);
            
            template_image = dataset.GetTemplateImage(PTKContext.LungROI);

            for index = 1 : number_points
                
                dicom_coords = PTKImageCoordinateUtilities.PtkToCornerCoordinates([ic(index), jc(index), kc(index)], template_image);
                coord_x = dicom_coords(1);
                coord_y = dicom_coords(2);
                coord_z = dicom_coords(3);
                
                density = density_values(index);
                output_string = sprintf('%6.6g,%6.6g,%6.6g,%6.6g\r\n', coord_x, coord_y, coord_z, density);
                fprintf(file_handle, regexprep(output_string, ' ', ''));
            end
            
            fclose(file_handle);
        end        
    end
end