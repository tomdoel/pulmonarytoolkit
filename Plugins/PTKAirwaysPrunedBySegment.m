classdef PTKAirwaysPrunedBySegment < PTKPlugin
    % PTKAirwaysPrunedBySegment. Plugin for pruning end branches from an airway
    %     tree according to the pulmonary segments
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
        ButtonText = 'Airways pruned<br>by segment'
        ToolTip = 'Creates an airway tree with end branches pruned'
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
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            airways_by_segment = dataset.GetResult('PTKSegmentsByNearestBronchus');
            start_branches = airways_by_segment.AirwaysBySegment.StartBranches;
            [airway_results, airway_image] = dataset.GetResult('PTKAirways');
            
            results_image = PTKGetAirwaysPrunedBySegment(start_branches, airway_results, airway_image);
                        
            % Store results and results image
            results = [];
            results.StartBranches = start_branches;
            results.PrunedSegmentsByLobeImage = results_image;
        end
        
        function results = GenerateImageFromResults(airway_results, image_templates, reporting)
            template_image = image_templates.GetTemplateImage(PTKContext.LungROI);
            
            start_tree = airway_results.StartBranches.Trachea;
            
            PTKVisualiseTreeModelCentreline(start_tree, template_image.VoxelSize, true);
            results = airway_results.PrunedSegmentsByLobeImage;            
        end        
    end
end