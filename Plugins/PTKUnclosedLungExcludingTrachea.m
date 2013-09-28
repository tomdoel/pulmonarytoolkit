classdef PTKUnclosedLungExcludingTrachea < PTKPlugin
    % PTKUnclosedLungExcludingTrachea. Plugin to segment the lung regions without
    % including the main airways.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKUnclosedLungExcludingTrachea runs the library function
    %     PTKGetMainRegionExcludingBorder on the lung image thresholded using the
    %     plugin PTKThresholdLungFiltered, in order to generate a segmented lung
    %     image which includes the airways. The main airways are then obtained
    %     using the plugin PTKAirways and dilated before being removed. The
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
        ButtonText = 'Lungs';
        ToolTip = 'Find unclosed lung region excluding the trachea and main bronchi'
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
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            threshold_image = dataset.GetResult('PTKUnclosedLungIncludingTrachea');
            
            % Remove first two generations of airway tree
            reporting.ShowProgress('Finding main airways and removing');
            [airway_tree, airway_image] = dataset.GetResult('PTKAirways');
            if dataset.IsGasMRI
                size_dilation_mm = 2.5;
                max_generation = 2;
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                size_dilation_mm = 2.5;
                max_generation = 2;
            else
                size_dilation_mm = 2.5;
                max_generation = 3;
            end

            if dataset.IsGasMRI || strcmp(dataset.GetImageInfo.Modality, 'MR')
                main_airways = PTKUnclosedLungExcludingTrachea.GetAirwaysBelowGeneration(results.AirwayTree, threshold_image, max_generation);
            else                
                airways_by_lobe = dataset.GetResult('PTKAirwaysLabelledByLobe');
                start_branches = airways_by_lobe.StartBranches;
                main_airways = PTKColourBranchesBelowLobe(start_branches, airway_tree.AirwayTree, threshold_image.BlankCopy);
                main_airways = (airway_image.RawImage == 1) & (main_airways == 0);
            end
            
            % Dilate the airways in order to remove airway walls. But we don't use too large a value, otherwise regions of the lungs will be removed
            ball_element = PTKImageUtilities.CreateBallStructuralElement(threshold_image.VoxelSize, size_dilation_mm);
            main_airways = imdilate(main_airways, ball_element);
            
            main_airways = ~main_airways;
            
            threshold_image_raw = threshold_image.RawImage;
            
            
            threshold_image_raw = threshold_image_raw & main_airways;
            threshold_image.ChangeRawImage(threshold_image_raw);
            
            results = threshold_image;
            results.ImageType = PTKImageType.Colormap;
        end
    end
    
    methods (Static, Access = private)
        
        function segmented_image = GetAirwaysBelowGeneration(airway_tree, template, max_generation_number)
            segmented_image = zeros(template.ImageSize, 'uint8');
            segments_to_do = airway_tree;
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                if segment.GenerationNumber <= max_generation_number
                    voxels = template.GlobalToLocalIndices(segment.GetAllAirwayPoints);
                    segmented_image(voxels) = 1;
                    segments_to_do = [segments_to_do, segment.Children];
                end
            end
        end
        
        function segmented_image = GetAirwaysUpToBronchi(bronchi, template)
            segmented_image = zeros(template.ImageSize, 'uint8');
            segments_to_do = bronchi;
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                voxels = template.GlobalToLocalIndices(segment.GetAllAirwayPoints);
                segmented_image(voxels) = 1;
                segments_to_do = [segments_to_do, segment.Parent];
            end
        end
        
    end
end