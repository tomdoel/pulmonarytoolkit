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
            
            lung_excluding_surface = dataset.GetResult('PTKLungsExcludingSurface');


            % Work out the interpolation grid spacing
            approx_number_grid_points = 30000;
            grid_spacing_mm = lung_excluding_surface.ComputeResamplingGridSpacing(approx_number_grid_points);
            grid_spacing_3 = [grid_spacing_mm, grid_spacing_mm, grid_spacing_mm];
            
            % Get the average density
            density_average_result = dataset.GetResult('PTKDensityAverage');
            density_average = density_average_result.DensityAverage;
            density_average_valid_mask = density_average_result.DensityAverageValidPointsMask;
            
            mean_density = mean(density_average.RawImage(density_average_valid_mask.RawImage(:)));
            disp(['Mean density:' num2str(mean_density)]);

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
                lung_excluding_surface_copy = lung_excluding_surface.Copy;
                lung_excluding_surface_copy.ResizeToMatch(lobes_copy);
                density_average_valid_mask_copy = density_average_valid_mask.Copy;
                density_average_valid_mask_copy.ResizeToMatch(lobes_copy);

                % Resample lobes and density
                lobes_copy.Resample(grid_spacing_3, '*nearest')
                density_average_copy.Resample(grid_spacing_3, '*nearest')
                density_average_valid_mask_copy.Resample(grid_spacing_3, '*nearest')
                lung_excluding_surface_copy.Resample(grid_spacing_3, '*nearest')
                
                local_indices_for_this_lobe = find(lobes_copy.RawImage & lung_excluding_surface_copy.RawImage);
                
                global_indices_for_this_lobe = lobes_copy.LocalToGlobalIndices(local_indices_for_this_lobe);
                [ic, jc, kc] = lobes_copy.GlobalIndicesToCoordinatesMm(global_indices_for_this_lobe);
                density_values = density_average_copy.RawImage(local_indices_for_this_lobe);
                PTKDensityGridPerLobe.SaveToFile(dataset, lobe_names{lobe_index}, ic, jc, kc, density_values)
            end
            
            results = dataset.GetTemplateImage(PTKContext.LungROI);
        end
        
        function SaveToFile(dataset, lobe_name, ic, jc, kc, density_values)
            results_directory = dataset.GetOutputPathAndCreateIfNecessary;
            file_name = ['DensityValues_' lobe_name '.txt'];
            template_image = dataset.GetTemplateImage(PTKContext.LungROI);
            
            PTKSaveListOfPointsAndValues(results_directory, file_name, ic, jc, kc, density_values, template_image)
        end        
    end
end