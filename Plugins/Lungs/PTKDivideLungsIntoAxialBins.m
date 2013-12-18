classdef PTKDivideLungsIntoAxialBins < PTKPlugin
    % PTKDivideLungsIntoAxialBins. Plugin for dividing the lungs into bins along
    % the cranial-caudal axis
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
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Axial<br>bins'
        ToolTip = 'Divides the lungs into bins along the cranial-caudal axis'
        Category = 'Lungs'
        
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Context = PTKContextSet.Lungs
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            whole_lung_mask = dataset.GetTemplateImage(PTKContext.Lungs);
            [~, ~, kc_mm] = whole_lung_mask.GetPTKCoordinates;
            bounds = whole_lung_mask.GetBounds;
            min_k = bounds(5);
            max_k = bounds(6);
            
            k_voxel_length_mm = whole_lung_mask.VoxelSize(3);
            k_values = min_k : max_k;
            k_values_mm = kc_mm(k_values);
            lung_base_mm = min(k_values_mm) - k_voxel_length_mm/2;
            lung_top_mm = max(k_values_mm) + k_voxel_length_mm/2;
            
            k_offsets_for_all_voxels_mm = kc_mm - lung_base_mm;
            
            % Compute the coordinates of the boundaries between bins
            bin_size_mm = 16;
            
            bin_locations = lung_base_mm + bin_size_mm/2 : bin_size_mm : lung_top_mm - bin_size_mm/2;
            bin_distance_from_base = bin_locations - lung_base_mm;
            
            % Compute bin numbers for each k coordinate
            bin_number = uint8(1 + max(0, floor(k_offsets_for_all_voxels_mm/bin_size_mm)));
            bin_matrix = repmat(shiftdim(bin_number, -2), whole_lung_mask.ImageSize(1), whole_lung_mask.ImageSize(2));
            bin_image_raw = bin_matrix.*uint8(whole_lung_mask.RawImage);
            bin_image = whole_lung_mask.BlankCopy;
            bin_image.ChangeRawImage(bin_image_raw);
            bin_image.ImageType = PTKImageType.Colormap;
            
            results = [];
            results.BinImage = bin_image;
            results.BinLocations = bin_locations;
            results.BinDistancesFromBase = bin_distance_from_base;
        end
        
        function results = GenerateImageFromResults(bins_results, image_templates, reporting)
            results = bins_results.BinImage;
        end        
    end
end