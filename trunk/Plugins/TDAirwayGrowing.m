classdef TDAirwayGrowing < TDPlugin
    
    properties
        ButtonText = 'Volume filling<br> airways'
        ToolTip = 'Grow the airways into the lobes'
        Category = 'Airways'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)

            left_and_right_lungs = dataset.GetResult('TDLeftAndRightLungs');
            lobes = dataset.GetResult('TDLobesFromFissurePlane');
                        
            airways_by_lobe = dataset.GetResult('TDReallocateAirwaysLabelledByLobe');
            

            upper_right_start_segment = airways_by_lobe.StartBranches.RightUpper;
            middle_right_start_segment = airways_by_lobe.StartBranches.RightMid;
            lower_right_start_segment = airways_by_lobe.StartBranches.RightLower;
            upper_left_start_segment = airways_by_lobe.StartBranches.LeftUpper;
            lower_left_start_segment = airways_by_lobe.StartBranches.LeftLower;
            
            right_lung = left_and_right_lungs.Copy;
            right_lung.ChangeRawImage(left_and_right_lungs.RawImage == 1);

            left_lung = left_and_right_lungs.Copy;
            left_lung.ChangeRawImage(left_and_right_lungs.RawImage == 2);
            
            template = left_and_right_lungs.BlankCopy;
            approx_number_points = 31000;
            airway_generator = TDAirwayGenerator(left_and_right_lungs, airways_by_lobe.StartBranches.Trachea, approx_number_points, reporting);
            
            
            reporting.ShowProgress('RIGHT - upper');
            reporting.UpdateProgressStage(0, 5);
            lobes_fill = lobes.Copy;
            lobes_fill.ChangeRawImage(lobes.RawImage == 1);
            lobes_fill.CropToFit;
            lobes_fill.AddBorder(2);
            airway_generator.GrowTree(lobes_fill, upper_right_start_segment, reporting)
            
            reporting.ShowProgress('RIGHT - middle');
            reporting.UpdateProgressStage(1, 5);
            lobes_fill = lobes.Copy;
            lobes_fill.ChangeRawImage(lobes.RawImage == 2);
            lobes_fill.CropToFit;
            lobes_fill.AddBorder(2);
            airway_generator.GrowTree(lobes_fill, middle_right_start_segment, reporting)
            
            reporting.ShowProgress('RIGHT - lower');
            reporting.UpdateProgressStage(2, 5);
            lobes_fill = lobes.Copy;
            lobes_fill.ChangeRawImage(lobes.RawImage == 4);
            lobes_fill.CropToFit;
            lobes_fill.AddBorder(2);
            airway_generator.GrowTree(lobes_fill, lower_right_start_segment, reporting)
                                    
            reporting.ShowProgress('LEFT - upper');
            reporting.UpdateProgressStage(3, 5);
            lobes_fill = lobes.Copy;
            lobes_fill.ChangeRawImage(lobes.RawImage == 5);
            lobes_fill.CropToFit;
            lobes_fill.AddBorder(2);
            airway_generator.GrowTree(lobes_fill, upper_left_start_segment, reporting)
            
            reporting.ShowProgress('LEFT - lower');
            reporting.UpdateProgressStage(4, 5);
            lobes_fill = lobes.Copy;
            lobes_fill.ChangeRawImage(lobes.RawImage == 6);
            lobes_fill.CropToFit;
            lobes_fill.AddBorder(2);
            airway_generator.GrowTree(lobes_fill, lower_left_start_segment, reporting)
            
            % Compute radius values based on Strahler orders
            airway_generator.AirwayTree.ComputeStrahlerOrders;
            
%             airway_generator.AirwayTree.GenerateBranchParameters;
            
            % Add values of tissue density
            density = dataset.GetResult('TDDensityAverage');
            airway_generator.AirwayTree.AddDensityValues(density);            

            results = [];
            results.Airways = airway_generator.AirwayTree;
            
            count_terminal_points = results.Airways.CountTerminalBranches;
            disp(['Number of terminal points: ' int2str(count_terminal_points)]);
            
            count_branches = results.Airways.CountBranches;
            disp(['Number of branches: ' int2str(count_branches)]);

            results.InitialImage = airway_generator.InitialApexImage;
            if isempty(results.InitialImage)
                results.InitialImage = zeros(template.ImageSize, 'uint8');
            end

        end
        
        function results = GenerateImageFromResults(airway_results, image_templates, reporting)
            template_image = image_templates.GetTemplateImage(TDContext.LungROI);

            % Visualising the entire airway tree is Matlab is slow if the number
            % of branches is greater than a few thousand
            % TDVisualiseAirwayGrowingTree(airway_results.Airways, reporting);

            results = template_image;
            results.ChangeRawImage(zeros(results.ImageSize, 'uint8'));
            results = TDDrawAirwayGrowingBranchesAsSegmentation(airway_results.Airways, template_image, reporting);
        end
        
        
    end
end
