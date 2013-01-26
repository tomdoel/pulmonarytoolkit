classdef TDAirwaysPruned < TDPlugin
    % TDAirwaysPruned. Plugin for pruning end branches from an airway tree
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
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
        ButtonText = 'Pruned <br>airways'
        ToolTip = 'Creates an airway tree with end branches pruned'
        Category = 'Airways'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            airways_by_lobe = dataset.GetResult('TDReallocateAirwaysLabelledByLobe');
            
            max_generation_inside_lobe = 1;
            
            TDAirwaysPruned.PruneAirwaysBelowGeneration(airways_by_lobe.StartBranches.RightUpper, max_generation_inside_lobe);
            TDAirwaysPruned.PruneAirwaysBelowGeneration(airways_by_lobe.StartBranches.RightMid, max_generation_inside_lobe);
            TDAirwaysPruned.PruneAirwaysBelowGeneration(airways_by_lobe.StartBranches.RightLower, max_generation_inside_lobe);
            TDAirwaysPruned.PruneAirwaysBelowGeneration(airways_by_lobe.StartBranches.LeftUpper, max_generation_inside_lobe);
            TDAirwaysPruned.PruneAirwaysBelowGeneration(airways_by_lobe.StartBranches.LeftLower, max_generation_inside_lobe);
            
            results = airways_by_lobe;
        end
        
        function results = GenerateImageFromResults(airway_results, image_templates, reporting)
            
            template_image = image_templates.GetTemplateImage(TDContext.LungROI);
            TDVisualiseTreeModelCentreline(airway_results.StartBranches.Trachea, template_image.VoxelSize);
            results = template_image;
            results.ChangeRawImage(zeros(template_image.ImageSize, 'uint8'));
        end
        
        
    end
    
    methods (Static, Access = private)
        function PruneAirwaysBelowGeneration(airway_tree, generation)
            if numel(airway_tree) > 1
                parent_branches = [airway_tree.Parent];
                
                if (numel(unique(parent_branches)) == 1) && (numel(airway_tree(1).Parent.Children) == numel(airway_tree))
                    % All branches have the same parent
                    airway_tree = airway_tree(1).Parent;
                else
                    generation = generation - 1;
                end
            end
            for airway = airway_tree
                branches = airway.GetBranchesAsList;
                max_generation_number = airway.GenerationNumber + generation - 1;
                for branch = branches
                    if branch.GenerationNumber >= max_generation_number
                        branch.RemoveChildren;
                    end
                end
            end
        end
    end
end
