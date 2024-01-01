classdef PTKAirwayGrowing < PTKPlugin
    % PTKAirwayGrowing. Plugin for generating an artificial airway tree
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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Volume filling<br> airways'
        ToolTip = 'Grow the airways into the lobes'
        Category = 'Airways'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)

            left_and_right_lungs = dataset.GetResult('PTKLeftAndRightLungs');
            lobes = dataset.GetResult('PTKLobes');
                        
            airways_by_lobe = dataset.GetResult('PTKReallocateAirwaysLabelledByLobe');
            

            upper_right_start_segment = airways_by_lobe.StartBranches.RightUpper;
            middle_right_start_segment = airways_by_lobe.StartBranches.RightMid;
            lower_right_start_segment = airways_by_lobe.StartBranches.RightLower;
            upper_left_start_segment = airways_by_lobe.StartBranches.LeftUpper;
            lower_left_start_segment = airways_by_lobe.StartBranches.LeftLower;
            
            right_lung = left_and_right_lungs.Copy;
            right_lung.ChangeRawImage(left_and_right_lungs.RawImage == 1);

            left_lung = left_and_right_lungs.Copy;
            left_lung.ChangeRawImage(left_and_right_lungs.RawImage == 2);
            
            template = left_and_right_lungs.BlankCopy();
            approx_number_points = 31000;
            airway_generator = PTKAirwayGenerator(left_and_right_lungs, airways_by_lobe.StartBranches.Trachea, approx_number_points, reporting);
            
            
            reporting.ShowProgress('RIGHT - upper');
            reporting.UpdateProgressStage(0, 5);
            lobes_fill = lobes.Copy;
            lobes_fill.ChangeRawImage(lobes.RawImage == PTKColormapLabels.RightUpperLobe);
            lobes_fill.CropToFit;
            lobes_fill.AddBorder(2);
            airway_generator.GrowTree(lobes_fill, upper_right_start_segment, reporting)
            
            reporting.ShowProgress('RIGHT - middle');
            reporting.UpdateProgressStage(1, 5);
            lobes_fill = lobes.Copy;
            lobes_fill.ChangeRawImage(lobes.RawImage == PTKColormapLabels.RightMiddleLobe);
            lobes_fill.CropToFit;
            lobes_fill.AddBorder(2);
            airway_generator.GrowTree(lobes_fill, middle_right_start_segment, reporting)
            
            reporting.ShowProgress('RIGHT - lower');
            reporting.UpdateProgressStage(2, 5);
            lobes_fill = lobes.Copy;
            lobes_fill.ChangeRawImage(lobes.RawImage == PTKColormapLabels.RightLowerLobe);
            lobes_fill.CropToFit;
            lobes_fill.AddBorder(2);
            airway_generator.GrowTree(lobes_fill, lower_right_start_segment, reporting)
                                    
            reporting.ShowProgress('LEFT - upper');
            reporting.UpdateProgressStage(3, 5);
            lobes_fill = lobes.Copy;
            lobes_fill.ChangeRawImage(lobes.RawImage == PTKColormapLabels.LeftUpperLobe);
            lobes_fill.CropToFit;
            lobes_fill.AddBorder(2);
            airway_generator.GrowTree(lobes_fill, upper_left_start_segment, reporting)
            
            reporting.ShowProgress('LEFT - lower');
            reporting.UpdateProgressStage(4, 5);
            lobes_fill = lobes.Copy;
            lobes_fill.ChangeRawImage(lobes.RawImage == PTKColormapLabels.LeftLowerLobe);
            lobes_fill.CropToFit;
            lobes_fill.AddBorder(2);
            airway_generator.GrowTree(lobes_fill, lower_left_start_segment, reporting)
            
            % Compute radius values based on Strahler orders
            airway_generator.AirwayTree.ComputeStrahlerOrders;
            
%             airway_generator.AirwayTree.GenerateBranchParameters;
            
            % Add values of tissue density
            density = dataset.GetResult('PTKDensityAverage');
            airway_generator.AirwayTree.AddDensityValues(density.DensityAverage);            

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
            template_image = image_templates.GetTemplateImage(PTKContext.LungROI);

            % Visualising the entire airway tree is Matlab is slow if the number
            % of branches is greater than a few thousand
            % PTKVisualiseAirwayGrowingTree(airway_results.Airways, reporting);

            results = template_image;
            results.ChangeRawImage(zeros(results.ImageSize, 'uint8'));
            results = PTKDrawAirwayGrowingBranchesAsSegmentation(airway_results.Airways, template_image, reporting);
        end
        
        
    end
end
