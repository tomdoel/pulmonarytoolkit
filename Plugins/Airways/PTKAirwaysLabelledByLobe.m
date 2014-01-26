classdef PTKAirwaysLabelledByLobe < PTKPlugin
    % PTKAirwaysLabelledByLobe. Plugin to visualise the airway tree labelled
    % according to lobe
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKAirwaysLabelledByLobe calls the PTKAirways plugin to segment the
    %     airway tree and the PTKAirwayCentreline plguin to obtain the airway
    %     centreline. It then calls the library function PTKGetAirwaysLabelledByLobe
    %     to allocate each broncus to the unique lobe it serves. Bronchi serving
    %     more than one lobe are not displayed.
    %
    %     The resulting image is a labelled image with nonzero values
    %     representing bronchi allocated to the following lobes:
    %         1 - Upper right lobe
    %         2 - Mid right lobe
    %         4 - Lower right lobe
    %         5 - Upper left lobe
    %         6 - Lower left lobe
    %         3 - Lobe could not be determined with certainty
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
 
    properties
        ButtonText = 'Airways <br>by lobe'
        ToolTip = 'Shows airways coloured by lobe, derived from analysis of the airway centreline'
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
            results_image = dataset.GetTemplateImage(PTKContext.LungROI);
            [airway_results, airway_image] = dataset.GetResult('PTKAirways');
            centreline_results = dataset.GetResult('PTKAirwayCentreline');

            % Generate a map of all the bronchi (one mapped colour for each bronchus)
            [airway_mapped_image, labelled_centreline] = PTKMapAirwayCentrelineToImage(centreline_results, airway_image);

            % Find the airways for each lobe
            start_branches_automatic = PTKGetAirwaysLabelledByLobe(results_image, labelled_centreline, reporting);

            airway_mapping = GetAirwayMappingForLobes(start_branches_automatic);
            airway_mapped_image.ChangeColorLabelMap(airway_mapping);

            
            % Find the airways for each lobe
            start_branches = PTKGetAirwaysLabelledByLobe(results_image, centreline_results.AirwayCentrelineTree, reporting);
            
            
            start_branches = GetLobarStartBranchesFromAirwayMap(start_branches.Trachea, airway_mapped_image);

            airways_by_lobe = PTKColourBranchesByLobe(start_branches, airway_results.AirwayTree, results_image);

            airway_image = 7*uint8(airway_image.RawImage == 1);
            airway_image(airways_by_lobe > 0) = airways_by_lobe(airways_by_lobe > 0);
            results_image.ChangeRawImage(airway_image);
            results_image.ImageType = PTKImageType.Colormap;
            results = [];
            results.AirwaysByLobeImage = results_image;
            results.StartBranches = start_branches;
        end
        
        function start_branches = GetLobarStartBranchesFromAirwayMap(tree_root, airway_mapped_image)

            left_upper_lobe = [];
            left_lower_lobe = [];
            right_upper_lobe = [];
            right_mid_lobe = [];
            right_lower_lobe = [];
            left_uncertain = [];
            
            % Generate the mapping for the lobes
            bronchi_to_do = PTKStack(tree_root);
            while ~bronchi_to_do.IsEmpty
                next_bronchus = bronchi_to_do.Pop;
                bronchus_label = next_bronchus.BronchusIndex;
                bronchus_mapping = airway_mapped_image.ColorLabelMap{bronchus_label};
                if bronchus_mapping == 7
                    bronchi_to_do.Push(next_bronchus.Children);
                else
                    switch bronchus_mapping
                        case PTKColormapLabels.LeftUpperLobe
                            left_upper_lobe = [left_upper_lobe, next_bronchus];

                        case PTKColormapLabels.LeftLowerLobe
                            left_upper_lobe = [left_lower_lobe, next_bronchus];
                            
                        case PTKColormapLabels.RightUpperLobe
                            right_upper_lobe = [right_upper_lobe, next_bronchus];
                            
                        case PTKColormapLabels.RightLowerLobe
                            right_lower_lobe = [right_lower_lobe, next_bronchus];
                            
                        case PTKColormapLabels.RightMiddleLobe
                            right_mid_lobe = [right_mid_lobe, next_bronchus];
                            
                        case 3
                            left_uncertain = [left_uncertain, next_bronchus];
                    end
                end
            end
            
            start_branches = [];
            start_branches.LeftLower = left_lower_lobe;
            start_branches.LeftUpper = left_upper_lobe;
            start_branches.RightUpper = right_upper_lobe;
            start_branches.RightLower = right_lower_lobe;
            start_branches.RightMid = right_mid_lobe;
            start_branches.LeftUncertain = left_uncertain;
        end
            
        function airway_mapping = GetAirwayMappingForLobes(start_branches)
            
            % Map the labels to the lobar colours
            airway_mapping = {};
            airway_mapping = MapTheseBranchesToLabel(airway_mapping, start_branches.LeftUpper, PTKColormapLabels.LeftUpperLobe);
            airway_mapping = MapTheseBranchesToLabel(airway_mapping, start_branches.LeftLower, PTKColormapLabels.LeftLowerLobe);
            airway_mapping = MapTheseBranchesToLabel(airway_mapping, start_branches.RightUpper, PTKColormapLabels.RightUpperLobe);
            airway_mapping = MapTheseBranchesToLabel(airway_mapping, start_branches.RightLower, PTKColormapLabels.RightLowerLobe);
            airway_mapping = MapTheseBranchesToLabel(airway_mapping, start_branches.RightMid, PTKColormapLabels.RightMiddleLobe);
            airway_mapping = MapTheseBranchesToLabel(airway_mapping, start_branches.LeftUncertain, 3);
        end
        
        function airway_mapping = MapTheseBranchesToLabel(airway_mapping, branch_list, label)
            for branch = branch_list
                airway_mapping{branch{1}.BronchusIndex} = label;
            end
        end
            
        function results = GenerateImageFromResults(airway_results, ~, ~)
            results = airway_results.AirwaysByLobeImage;
        end
    end
end