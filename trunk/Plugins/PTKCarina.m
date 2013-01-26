classdef TDCarina < TDPlugin
    % TDCarina. Plugin to find the carina point in the airways
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
 
    properties
        ButtonText = 'Carina'
        ToolTip = 'Finds the carina point in the airways'
        Category = 'Airways'
 
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            main_bronchi = dataset.GetTemplateImage(TDContext.LungROI);
            airway_results = dataset.GetResult('TDAirways');
            labeled_region = TDCarina.GetTracheaAndMainBronchi(airway_results.AirwayTree, main_bronchi);
            main_bronchi.ChangeRawImage(labeled_region);
            main_bronchi.ImageType = TDImageType.Colormap;
            bronchi_surface = main_bronchi.BlankCopy;
            bronchi_surface.ChangeRawImage(TDGetSurfaceFromSegmentation(main_bronchi.RawImage));
            
            k_found = TDCarina.GetCarinaSliceIndex(main_bronchi, reporting);

            next_slice = main_bronchi.GetSlice(k_found + 1, TDImageOrientation.Axial);
            cc = bwconncomp(next_slice);
            
            next_slice_1 = false(size(next_slice));
            next_slice_1(cc.PixelIdxList{1}) = true;
            next_slice_1 = bwdist(next_slice_1);
            next_slice_2 = false(size(next_slice));
            next_slice_2(cc.PixelIdxList{2}) = true;
            next_slice_2 = bwdist(next_slice_2);
            
            added_dt = next_slice_1.^2 + next_slice_2.^2;
            
            slice = main_bronchi.GetSlice(k_found, TDImageOrientation.Axial);
            surface_slice = bronchi_surface.GetSlice(k_found, TDImageOrientation.Axial);
            slice = slice & surface_slice;
            candidate_indices = find(slice);
            added_dt_at_candidate_indices = added_dt(candidate_indices);
            
            [~, min_index] = min(added_dt_at_candidate_indices);
            slice_index = candidate_indices(min_index);
            
            [min_i, min_j] = ind2sub(size(next_slice), slice_index);
            
            results = [];
            results.Carina = main_bronchi.LocalToGlobalCoordinates([min_i, min_j, k_found]);
        end
        
        function results = GenerateImageFromResults(carina_results, image_templates, reporting)
            template_image = image_templates.GetTemplateImage(TDContext.LungROI);

            carina_global = carina_results.Carina;
            
            % Display coordinates in mm
            [c_i, c_j, c_k] = template_image.GlobalCoordinatesToCoordinatesMm(carina_global);
            disp(['Carina coordinates: ' num2str(c_i) 'mm, ' num2str(c_j) 'mm, ' num2str(c_k) 'mm']);
            
            
            % Convert to local coordinaes relative to the ROI
            top_of_carina = template_image.GlobalToLocalCoordinates(carina_global);
            image_size = template_image.ImageSize;
            
            carina = zeros(image_size, 'uint8');
            
            carina(top_of_carina(1), top_of_carina(2), top_of_carina(3)) = 3;
            carina = TDImageUtilities.DrawBoxAround(carina, top_of_carina, 5, 3);
            
            
            results = template_image;
            results.ChangeRawImage(carina);
            results.ImageType = TDImageType.Colormap;
            
            reporting.ChangeViewingPosition(top_of_carina);
        end
        
    end
    
    methods (Static, Access = private)

        function k_found = GetCarinaSliceIndex(main_bronchi, reporting)
            
            bounds = main_bronchi.GetBounds;
            k_min = bounds(5);
            k_max = bounds(6);
            
            k_index = round((k_max - k_min)/2);
            k_continue = true;
            k_found = [];
            
            while k_continue            
                next_slice = main_bronchi.GetSlice(k_index, TDImageOrientation.Axial);
                cc = bwconncomp(next_slice);
                if cc.NumObjects == 2
                    k_continue = false;
                    if isempty(k_found)
                        reporting.Error('TDCarina:CarinaNotFound', 'The carina could not be located');
                    end
                else
                    k_found = k_index;
                    k_index = k_index + 1;
                    if k_index > k_max
                        reporting.Error('TDCarina:CarinaNotFound', 'The carina could not be located');
                    end
                end
            end
        end
        
        function segmented_image = GetTracheaAndMainBronchi(airway_tree, template)
            segments_to_do = [airway_tree, airway_tree.Children];
            segmented_image = zeros(template.ImageSize, 'uint8');
            
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                segmented_image(template.GlobalToLocalIndices(segment.GetAllAirwayPoints)) = 1;
            end
        end
    end
end